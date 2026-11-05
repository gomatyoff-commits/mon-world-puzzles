@tool
extends RefCounted
## Implémentation des commandes appelées par le serveur MCP.
## Chaque commande "_cmd_<nom>(params: Dictionary)" renvoie un Variant
## sérialisable en JSON, ou _err("message") en cas d'erreur.

const MAX_LISTED_FILES := 2000

var _plugin: EditorPlugin


func _init(plugin: EditorPlugin) -> void:
	_plugin = plugin


func execute(command: String, params) -> Variant:
	if typeof(params) != TYPE_DICTIONARY:
		params = {}
	var method := "_cmd_" + command
	if command.is_empty() or not has_method(method):
		return _err("Commande inconnue : %s" % command)
	return call(method, params)


# --------------------------------------------------------------------------
# Projet et scènes
# --------------------------------------------------------------------------

func _cmd_get_project_info(_params: Dictionary) -> Variant:
	var root := _root()
	return {
		"project_name": ProjectSettings.get_setting("application/config/name", ""),
		"project_path": ProjectSettings.globalize_path("res://"),
		"godot_version": Engine.get_version_info().get("string", ""),
		"main_scene": ProjectSettings.get_setting("application/run/main_scene", ""),
		"edited_scene": root.scene_file_path if root else null,
		"open_scenes": Array(EditorInterface.get_open_scenes()).filter(func(p): return p != ""),
		"is_playing": EditorInterface.is_playing_scene(),
	}


func _cmd_get_scene_tree(params: Dictionary) -> Variant:
	var root := _root()
	if root == null:
		return _err("Aucune scène ouverte dans l'éditeur.")
	var max_depth := int(params.get("max_depth", -1))
	return {"scene_path": root.scene_file_path, "tree": _node_info(root, root, 0, max_depth)}


func _cmd_open_scene(params: Dictionary) -> Variant:
	var path := str(params.get("path", ""))
	if not ResourceLoader.exists(path):
		return _err("Scène introuvable : %s" % path)
	EditorInterface.open_scene_from_path(path)
	return {"opened": path}


func _cmd_create_scene(params: Dictionary) -> Variant:
	var path := str(params.get("path", ""))
	var check := _check_res_path(path)
	if check != "":
		return _err(check)
	if not path.ends_with(".tscn"):
		return _err("Le chemin doit se terminer par .tscn")
	if FileAccess.file_exists(path):
		return _err("Une scène existe déjà à %s" % path)
	var root_type := str(params.get("root_type", "Node2D"))
	var type_error := _check_node_type(root_type)
	if type_error != "":
		return _err(type_error)
	var node: Node = ClassDB.instantiate(root_type)
	node.name = str(params.get("root_name", path.get_file().get_basename().to_pascal_case()))
	var packed := PackedScene.new()
	var err := packed.pack(node)
	node.free()
	if err != OK:
		return _err("Échec de la création de la scène (erreur %d)." % err)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	err = ResourceSaver.save(packed, path)
	if err != OK:
		return _err("Échec de l'enregistrement de %s (erreur %d)." % [path, err])
	EditorInterface.get_resource_filesystem().update_file(path)
	if params.get("open", true):
		EditorInterface.open_scene_from_path(path)
	return {"created": path, "root_type": root_type}


func _cmd_save_scene(params: Dictionary) -> Variant:
	var root := _root()
	if root == null:
		return _err("Aucune scène ouverte dans l'éditeur.")
	var path := str(params.get("path", ""))
	if path != "":
		var check := _check_res_path(path)
		if check != "":
			return _err(check)
		EditorInterface.save_scene_as(path)
		return {"saved": path}
	if root.scene_file_path == "":
		return _err("La scène n'a pas encore de chemin : passe un paramètre 'path'.")
	var err := EditorInterface.save_scene()
	if err != OK:
		return _err("Échec de l'enregistrement (erreur %d)." % err)
	return {"saved": root.scene_file_path}


# --------------------------------------------------------------------------
# Nœuds (toutes les modifications passent par l'historique Annuler/Refaire)
# --------------------------------------------------------------------------

func _cmd_add_node(params: Dictionary) -> Variant:
	var root := _root()
	if root == null:
		return _err("Aucune scène ouverte dans l'éditeur.")
	var parent := _find_node(str(params.get("parent_path", ".")))
	if parent == null:
		return _err("Nœud parent introuvable : %s" % params.get("parent_path", "."))
	var type := str(params.get("type", ""))
	var node: Node
	if type.begins_with("res://"):
		var res = load(type)
		if not res is PackedScene:
			return _err("%s n'est pas une scène (.tscn/.scn)." % type)
		node = res.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	else:
		var type_error := _check_node_type(type)
		if type_error != "":
			return _err(type_error)
		node = ClassDB.instantiate(type)
	var node_name := str(params.get("name", ""))
	if node_name != "":
		node.name = node_name
	var script_path := str(params.get("script", ""))
	if script_path != "":
		var script = load(script_path)
		if not script is Script:
			node.free()
			return _err("Script introuvable : %s" % script_path)
		node.set_script(script)
	var props = params.get("properties", {})
	if typeof(props) == TYPE_DICTIONARY:
		for key in props:
			var prop_error := _apply_property(node, str(key), props[key])
			if prop_error != "":
				node.free()
				return _err(prop_error)

	var ur := _plugin.get_undo_redo()
	ur.create_action("MCP : ajouter %s" % node.name)
	ur.add_do_method(parent, "add_child", node, true)
	ur.add_do_method(node, "set_owner", root)
	ur.add_do_reference(node)
	ur.add_undo_method(parent, "remove_child", node)
	ur.commit_action()
	return {"path": String(root.get_path_to(node)), "name": String(node.name), "type": node.get_class()}


func _cmd_delete_node(params: Dictionary) -> Variant:
	var root := _root()
	if root == null:
		return _err("Aucune scène ouverte dans l'éditeur.")
	var node := _find_node(str(params.get("path", "")))
	if node == null:
		return _err("Nœud introuvable : %s" % params.get("path", ""))
	if node == root:
		return _err("Impossible de supprimer la racine de la scène.")
	var parent := node.get_parent()
	var index := node.get_index()
	var owners: Array = []
	_collect_owners(node, owners)
	var deleted_path := String(root.get_path_to(node))

	var ur := _plugin.get_undo_redo()
	ur.create_action("MCP : supprimer %s" % node.name)
	ur.add_do_method(parent, "remove_child", node)
	ur.add_undo_method(parent, "add_child", node)
	ur.add_undo_method(parent, "move_child", node, index)
	for pair in owners:
		ur.add_undo_method(pair[0], "set_owner", pair[1])
	ur.add_undo_reference(node)
	ur.commit_action()
	return {"deleted": deleted_path}


func _cmd_set_node_properties(params: Dictionary) -> Variant:
	var root := _root()
	var node := _find_node(str(params.get("path", "")))
	if node == null:
		return _err("Nœud introuvable : %s" % params.get("path", ""))
	var props = params.get("properties", {})
	if typeof(props) != TYPE_DICTIONARY or props.is_empty():
		return _err("'properties' doit être un objet non vide, ex. {\"position\": \"Vector2(100, 50)\"}.")
	var changes: Array = []
	for key in props:
		var prop := str(key)
		if not prop in node:
			return _err("Propriété inconnue '%s' sur %s (%s)." % [prop, node.name, node.get_class()])
		var old = node.get(prop)
		var new_value = _coerce(props[key], old)
		if _is_missing_resource(props[key], new_value):
			return _err("Ressource introuvable : %s" % props[key])
		changes.append([prop, new_value, old])

	var ur := _plugin.get_undo_redo()
	ur.create_action("MCP : modifier %s" % node.name)
	for c in changes:
		ur.add_do_property(node, c[0], c[1])
		ur.add_undo_property(node, c[0], c[2])
	ur.commit_action()

	var result := {}
	for c in changes:
		result[c[0]] = _ser(node.get(c[0]))
	return {"path": String(root.get_path_to(node)), "properties": result}


func _cmd_get_node_properties(params: Dictionary) -> Variant:
	var root := _root()
	var node := _find_node(str(params.get("path", "")))
	if node == null:
		return _err("Nœud introuvable : %s" % params.get("path", ""))
	var filter := str(params.get("filter", "")).to_lower()
	var skip_flags := PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SUBGROUP | PROPERTY_USAGE_CATEGORY
	var out := {}
	for p in node.get_property_list():
		var usage: int = p["usage"]
		if not (usage & PROPERTY_USAGE_EDITOR) or (usage & skip_flags):
			continue
		var prop_name: String = p["name"]
		if filter != "" and not prop_name.to_lower().contains(filter):
			continue
		out[prop_name] = _ser(node.get(prop_name))
	return {"path": String(root.get_path_to(node)), "type": node.get_class(), "properties": out}


# --------------------------------------------------------------------------
# Exécution du jeu et journaux
# --------------------------------------------------------------------------

func _cmd_run_project(params: Dictionary) -> Variant:
	var scene := str(params.get("scene", ""))
	if scene == "current":
		if _root() == null:
			return _err("Aucune scène ouverte à lancer.")
		EditorInterface.play_current_scene()
	elif scene != "":
		if not ResourceLoader.exists(scene):
			return _err("Scène introuvable : %s" % scene)
		EditorInterface.play_custom_scene(scene)
	else:
		if str(ProjectSettings.get_setting("application/run/main_scene", "")) == "":
			return _err("Aucune scène principale définie. Passe scene=\"current\" ou un chemin res://.")
		EditorInterface.play_main_scene()
	return {"playing": true, "scene": scene if scene != "" else "main"}


func _cmd_stop_project(_params: Dictionary) -> Variant:
	EditorInterface.stop_playing_scene()
	return {"playing": false}


func _cmd_get_editor_output(params: Dictionary) -> Variant:
	var base := EditorInterface.get_base_control()
	var logs := base.find_children("*", "EditorLog", true, false)
	if logs.is_empty():
		return _err("Panneau Sortie introuvable.")
	var labels := logs[0].find_children("*", "RichTextLabel", true, false)
	if labels.is_empty():
		return _err("Texte du panneau Sortie introuvable.")
	return {"output": _tail(labels[0].get_parsed_text(), int(params.get("lines", 100)))}


func _cmd_get_game_log(params: Dictionary) -> Variant:
	var path := "user://logs/godot.log"
	if not FileAccess.file_exists(path):
		return _err("Aucun journal du jeu trouvé (%s). Lance le jeu au moins une fois et vérifie que debug/file_logging/enable_file_logging est activé." % ProjectSettings.globalize_path(path))
	return {
		"is_playing": EditorInterface.is_playing_scene(),
		"log_file": ProjectSettings.globalize_path(path),
		"log": _tail(FileAccess.get_file_as_string(path), int(params.get("lines", 100))),
	}


# --------------------------------------------------------------------------
# Fichiers du projet (limités à res://)
# --------------------------------------------------------------------------

func _cmd_list_files(params: Dictionary) -> Variant:
	var path := str(params.get("path", "res://"))
	var check := _check_res_path(path)
	if check != "":
		return _err(check)
	if not DirAccess.dir_exists_absolute(path):
		return _err("Dossier introuvable : %s" % path)
	var exts: Array = []
	var raw_exts = params.get("extensions", [])
	if typeof(raw_exts) == TYPE_ARRAY:
		for e in raw_exts:
			exts.append(str(e).trim_prefix(".").to_lower())
	var files: Array = []
	_list_dir(path, bool(params.get("recursive", true)), exts, files)
	return {"files": files, "truncated": files.size() >= MAX_LISTED_FILES}


func _cmd_read_file(params: Dictionary) -> Variant:
	var path := str(params.get("path", ""))
	var check := _check_res_path(path)
	if check != "":
		return _err(check)
	if not FileAccess.file_exists(path):
		return _err("Fichier introuvable : %s" % path)
	return {"path": path, "content": FileAccess.get_file_as_string(path)}


func _cmd_write_file(params: Dictionary) -> Variant:
	var path := str(params.get("path", ""))
	var check := _check_res_path(path)
	if check != "":
		return _err(check)
	var content := str(params.get("content", ""))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return _err("Impossible d'écrire %s (erreur %d)." % [path, FileAccess.get_open_error()])
	f.store_string(content)
	f.close()

	var result := {"written": path, "bytes": content.to_utf8_buffer().size()}
	# Recharge le script dans l'éditeur et signale les erreurs de syntaxe.
	if path.get_extension() == "gd":
		var script = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
		if script is GDScript:
			script.source_code = content
			var err: int = script.reload(true)
			result["parse_ok"] = err == OK
			if err != OK:
				result["hint"] = "Le script contient des erreurs : appelle get_editor_output pour les voir."
	EditorInterface.get_resource_filesystem().scan()
	return result


# --------------------------------------------------------------------------
# Outils avancés
# --------------------------------------------------------------------------

func _cmd_execute_gdscript(params: Dictionary) -> Variant:
	var code := str(params.get("code", ""))
	if code.strip_edges() == "":
		return _err("Code vide.")
	# Retire l'indentation commune puis indente le tout dans la fonction run().
	var lines := code.replace("\r", "").split("\n")
	var common := -1
	for line in lines:
		if line.strip_edges() == "":
			continue
		var n := line.length() - line.lstrip(" \t").length()
		common = n if common < 0 else mini(common, n)
	var dedented: Array[String] = []
	var indent := "\t"
	for line in lines:
		var l := line.substr(maxi(common, 0)) if line.strip_edges() != "" else ""
		if l.begins_with(" "):
			indent = "    "  # le code utilise des espaces : ne pas mélanger avec des tabulations
		dedented.append(l)
	var body := ""
	for l in dedented:
		body += (indent + l if l != "" else "") + "\n"
	var src := "@tool\nextends RefCounted\n\nfunc run(editor, scene_root: Node, plugin: EditorPlugin):\n" + body
	var script := GDScript.new()
	script.source_code = src
	if script.reload() != OK:
		return _err("Erreur de compilation du code GDScript. Appelle get_editor_output pour voir le détail.")
	var obj = script.new()
	var result = obj.run(EditorInterface, _root(), _plugin)
	return {"result": _ser(result)}


func _cmd_get_editor_screenshot(params: Dictionary) -> Variant:
	var target := str(params.get("target", "editor"))
	var vp: Viewport
	match target:
		"2d":
			vp = EditorInterface.get_editor_viewport_2d()
		"3d":
			vp = EditorInterface.get_editor_viewport_3d(0)
		_:
			vp = EditorInterface.get_base_control().get_viewport()
	if vp == null or vp.get_texture() == null:
		return _err("Viewport '%s' indisponible." % target)
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		return _err("Capture vide (l'éditeur tourne peut-être sans affichage).")
	var max_w := int(params.get("max_width", 1280))
	if max_w > 0 and img.get_width() > max_w:
		img.resize(max_w, int(img.get_height() * max_w / float(img.get_width())), Image.INTERPOLATE_LANCZOS)
	return {
		"__image": Marshalls.raw_to_base64(img.save_png_to_buffer()),
		"width": img.get_width(),
		"height": img.get_height(),
	}


# --------------------------------------------------------------------------
# Utilitaires
# --------------------------------------------------------------------------

func _err(message: String) -> Dictionary:
	return {"__error": message}


func _root() -> Node:
	return EditorInterface.get_edited_scene_root()


## Chemins relatifs à la racine de la scène : ".", "Player", "Player/Sprite2D".
## Le nom de la racine en préfixe est accepté ("Main/Player").
func _find_node(path: String) -> Node:
	var root := _root()
	if root == null:
		return null
	path = path.strip_edges().trim_prefix("/")
	if path == "" or path == "." or path == String(root.name):
		return root
	if path.begins_with(String(root.name) + "/"):
		path = path.substr(String(root.name).length() + 1)
	return root.get_node_or_null(NodePath(path))


func _node_info(node: Node, root: Node, depth: int, max_depth: int) -> Dictionary:
	var info := {"name": String(node.name), "type": node.get_class(), "path": String(root.get_path_to(node))}
	var script = node.get_script()
	if script:
		info["script"] = script.resource_path
	if node != root and node.scene_file_path != "":
		info["instance_of"] = node.scene_file_path
	var children: Array = []
	if max_depth < 0 or depth < max_depth:
		for child in node.get_children():
			if child.owner == root:
				children.append(_node_info(child, root, depth + 1, max_depth))
	elif node.get_child_count() > 0:
		info["child_count"] = node.get_child_count()
	if not children.is_empty():
		info["children"] = children
	return info


func _collect_owners(node: Node, out: Array) -> void:
	out.append([node, node.owner])
	for child in node.get_children():
		_collect_owners(child, out)


func _check_node_type(type: String) -> String:
	if type == "":
		return "Paramètre 'type' manquant (ex. \"Sprite2D\" ou \"res://player.tscn\")."
	if not ClassDB.class_exists(type):
		return "Type inconnu : %s" % type
	if not ClassDB.is_parent_class(type, "Node"):
		return "%s n'est pas un type de nœud." % type
	if not ClassDB.can_instantiate(type):
		return "%s ne peut pas être instancié (classe abstraite)." % type
	return ""


func _check_res_path(path: String) -> String:
	if not path.begins_with("res://"):
		return "Le chemin doit commencer par res:// (reçu : %s)." % path
	if path.contains(".."):
		return "Les chemins contenant '..' sont refusés."
	return ""


func _apply_property(node: Node, prop: String, value) -> String:
	if not prop in node:
		return "Propriété inconnue '%s' sur %s." % [prop, node.get_class()]
	var new_value = _coerce(value, node.get(prop))
	if _is_missing_resource(value, new_value):
		return "Ressource introuvable : %s" % value
	node.set(prop, new_value)
	return ""


func _is_missing_resource(raw, coerced) -> bool:
	return raw is String and raw.begins_with("res://") and coerced == null


## Convertit une valeur JSON vers le type de la propriété ciblée.
## Accepte la syntaxe Godot en texte ("Vector2(10, 20)", "Color(1, 0, 0)"),
## des tableaux ([10, 20]), des objets ({"x": 10, "y": 20}),
## des couleurs HTML ("#ff0000") et des chemins de ressources ("res://icon.svg").
func _coerce(value, current) -> Variant:
	var t := typeof(current)
	if value is String:
		var s: String = value
		if s.begins_with("res://") and (t == TYPE_OBJECT or t == TYPE_NIL):
			return load(s) if ResourceLoader.exists(s) else null
		match t:
			TYPE_STRING:
				return s
			TYPE_STRING_NAME:
				return StringName(s)
			TYPE_NODE_PATH:
				return NodePath(s)
			TYPE_COLOR:
				if not s.begins_with("Color("):
					return Color(s)
		var parsed = str_to_var(s)
		if parsed != null or s == "null":
			return parsed
		return s
	if value is Array:
		var a: Array = value
		match t:
			TYPE_VECTOR2:
				return Vector2(a[0], a[1])
			TYPE_VECTOR2I:
				return Vector2i(int(a[0]), int(a[1]))
			TYPE_VECTOR3:
				return Vector3(a[0], a[1], a[2])
			TYPE_VECTOR3I:
				return Vector3i(int(a[0]), int(a[1]), int(a[2]))
			TYPE_COLOR:
				return Color(a[0], a[1], a[2], a[3] if a.size() > 3 else 1.0)
			TYPE_RECT2:
				return Rect2(a[0], a[1], a[2], a[3])
	if value is Dictionary:
		var d: Dictionary = value
		match t:
			TYPE_VECTOR2:
				return Vector2(d.get("x", 0), d.get("y", 0))
			TYPE_VECTOR2I:
				return Vector2i(int(d.get("x", 0)), int(d.get("y", 0)))
			TYPE_VECTOR3:
				return Vector3(d.get("x", 0), d.get("y", 0), d.get("z", 0))
			TYPE_COLOR:
				return Color(d.get("r", 0), d.get("g", 0), d.get("b", 0), d.get("a", 1))
	match t:
		TYPE_INT:
			if value is float or value is bool:
				return int(value)
		TYPE_FLOAT:
			if value is int:
				return float(value)
		TYPE_BOOL:
			if value is int or value is float:
				return bool(value)
	return value


## Convertit une valeur Godot en valeur JSON lisible.
## Les types Godot sont rendus dans leur syntaxe texte ("Vector2(10, 20)").
func _ser(v) -> Variant:
	match typeof(v):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return v
		TYPE_STRING_NAME, TYPE_NODE_PATH:
			return str(v)
		TYPE_OBJECT:
			if not is_instance_valid(v):
				return null
			if v is Resource and v.resource_path != "" and not v.resource_path.contains("::"):
				return v.resource_path
			if v is Node:
				return "<%s %s>" % [v.get_class(), v.name]
			return "<%s>" % v.get_class()
		TYPE_ARRAY:
			var arr: Array = []
			for item in v:
				arr.append(_ser(item))
			return arr
		TYPE_DICTIONARY:
			var dict := {}
			for k in v:
				dict[str(k)] = _ser(v[k])
			return dict
		_:
			return var_to_str(v)


func _tail(text: String, lines: int) -> String:
	var all := text.split("\n")
	if lines <= 0 or all.size() <= lines:
		return text
	return "\n".join(all.slice(all.size() - lines))


func _list_dir(path: String, recursive: bool, exts: Array, out: Array) -> void:
	if out.size() >= MAX_LISTED_FILES:
		return
	for f in DirAccess.get_files_at(path):
		if exts.is_empty() or f.get_extension().to_lower() in exts:
			out.append(path.path_join(f))
			if out.size() >= MAX_LISTED_FILES:
				return
	if recursive:
		for d in DirAccess.get_directories_at(path):
			if d.begins_with("."):
				continue
			_list_dir(path.path_join(d), recursive, exts, out)
