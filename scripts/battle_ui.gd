# battle_ui.gd  -> attaché au nœud "UI" (CanvasLayer)
extends CanvasLayer

const CELL := 160
const ROWS := 5
const BOARD_MARGIN := 20

var enemy_widgets: Array = []
var combo_label: Label
var result_label: Label
var team_hp_bar: ProgressBar
var enemy_row: HBoxContainer
var wave_label: Label
var team_widgets: Array = []
signal skill_pressed(index: int)
const BALL := 40          # taille de la boule
const FLIGHT := 0.35      # durée du trajet (secondes)

func _ready() -> void:
	_build_ui()
	refresh_all()

func _build_ui() -> void:
	var vp := get_viewport().get_visible_rect().size
	var board_h := ROWS * CELL
	
	# --- ENNEMIS (haut) : image + vie EN DESSOUS ---
	enemy_row = HBoxContainer.new()
	wave_label = Label.new()
	wave_label.add_theme_font_size_override("font_size", 26)
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.position = Vector2(0, 20)
	wave_label.size = Vector2(get_viewport().get_visible_rect().size.x, 30)
	add_child(wave_label)
	enemy_row.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_row.add_theme_constant_override("separation", 40)
	enemy_row.position = Vector2(0, 60)
	enemy_row.size = Vector2(vp.x, 320)
	add_child(enemy_row)
	for e in GameManager.enemies:
		var w := _make_monster_widget(e, 150, false)   # vie en dessous
		enemy_row.add_child(w["root"])
		enemy_widgets.append(w)
	
	# --- COMBO (centre) ---
	combo_label = Label.new()
	combo_label.add_theme_font_size_override("font_size", 52)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.position = Vector2(0, vp.y * 0.42)
	combo_label.size = Vector2(vp.x, 70)
	add_child(combo_label)
	
	# --- ÉQUIPE (au-dessus du board) : vie AU-DESSUS de l'image ---
	var team_h := 130
	var team_row := HBoxContainer.new()
	team_row.alignment = BoxContainer.ALIGNMENT_CENTER
	team_row.add_theme_constant_override("separation", 10)
	team_row.position = Vector2(0, vp.y - board_h - BOARD_MARGIN - team_h - 8)
	team_row.size = Vector2(vp.x, team_h)
	add_child(team_row)
	for m in GameManager.team:
		var w := _make_monster_widget(m, 90, true, false)     # vie au-dessus
		var skill_lbl := Label.new()
		skill_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		skill_lbl.add_theme_font_size_override("font_size", 18)
		w["root"].add_child(skill_lbl)
		w["skill"] = skill_lbl
		var idx := team_widgets.size()
		w["root"].gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				skill_pressed.emit(idx))
		team_row.add_child(w["root"])
		team_widgets.append(w)
	
	# --- BARRE DE VIE COMMUNE de l'équipe (au-dessus des images) ---
	team_hp_bar = ProgressBar.new()
	team_hp_bar.show_percentage = false
	team_hp_bar.max_value = GameManager.team_max_hp()
	team_hp_bar.value = GameManager.team_total_hp()
	team_hp_bar.custom_minimum_size = Vector2(vp.x * 0.85, 26)
	team_hp_bar.position = Vector2(vp.x * 0.075, team_row.position.y - 40)
	var hp_style := StyleBoxFlat.new()
	hp_style.bg_color = Color(0.2, 0.85, 0.35)      # barre verte
	hp_style.set_corner_radius_all(6)
	team_hp_bar.add_theme_stylebox_override("fill", hp_style)
	add_child(team_hp_bar)
	
	# --- Résultat (caché) ---
	result_label = Label.new()
	result_label.add_theme_font_size_override("font_size", 64)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.position = Vector2(0, vp.y * 0.35)
	result_label.size = Vector2(vp.x, 80)
	result_label.visible = false
	add_child(result_label)
	
# Crée un widget monstre : { root, bar, turn }
# hp_on_top = true -> barre de vie AU-DESSUS de l'image (équipe)
func _make_monster_widget(mon: MonsterData, img_size: int, hp_on_top: bool, with_bar := true) -> Dictionary:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)

	var bar: ProgressBar = null
	if with_bar:
		bar = ProgressBar.new()
		bar.max_value = mon.max_hp
		bar.value = mon.hp
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(img_size, 22)
		var style := StyleBoxFlat.new()
		style.bg_color = Elements.COLORS[mon.element]
		bar.add_theme_stylebox_override("fill", style)

		# PV en chiffres sur la barre
		var hp_lbl := Label.new()
		hp_lbl.name = "HpLabel"
		hp_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hp_lbl.add_theme_font_size_override("font_size", 16)
		hp_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		hp_lbl.add_theme_constant_override("outline_size", 4)
		hp_lbl.text = "%d / %d" % [mon.hp, mon.max_hp]
		bar.add_child(hp_lbl)

	var img := TextureRect.new()
	img.texture = mon.texture
	img.custom_minimum_size = Vector2(img_size, img_size)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if with_bar and hp_on_top:
		box.add_child(bar)
		box.add_child(img)
		return { "mon": mon, "root": box, "bar": bar, "turn": null }
	elif with_bar:
		var turn := Label.new()
		turn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(img)
		box.add_child(bar)
		box.add_child(turn)
		return { "mon": mon, "root": box, "bar": bar, "turn": turn }
	else:
		box.add_child(img)
		return { "mon": mon, "root": box, "bar": bar, "turn": null }
func refresh_all() -> void:
	# ennemis : barre de vie, compteur de tour, masqué si mort
	for w in enemy_widgets:
		var e: MonsterData = w["mon"]
		w["bar"].value = e.hp
		w["bar"].get_node("HpLabel").text = "%d / %d" % [e.hp, e.max_hp]
		w["turn"].text = "Tour : " + str(e.turn_counter)
		w["root"].visible = e.is_alive()

	for w in team_widgets:
		var m: MonsterData = w["mon"]
		var lbl: Label = w["skill"]
		if m.skill_id == "":
			lbl.text = ""
		elif m.skill_cd <= 0:
			lbl.text = "⚡ PRÊT"
			lbl.add_theme_color_override("font_color", UIStyle.COL_GOLD)
		else:
			lbl.text = "⏳ %d" % m.skill_cd
			lbl.add_theme_color_override("font_color", Color.WHITE)
	
	# barre de vie commune de l'équipe
	team_hp_bar.max_value = GameManager.team_max_hp()
	team_hp_bar.value = GameManager.team_total_hp()
	var ratio: float = float(GameManager.team_total_hp()) / float(max(1, GameManager.team_max_hp()))
	var col := Color(0.2, 0.85, 0.35) if ratio > 0.5 else (Color(0.95, 0.75, 0.2) if ratio > 0.25 else Color(0.9, 0.25, 0.25))
	team_hp_bar.get_theme_stylebox("fill").bg_color = col
	
	if wave_label:
		wave_label.text = ("Vague %d / %d" % [GameManager.current_wave, GameManager.total_waves]) if GameManager.total_waves > 1 else ""
	
func show_combo(count: int) -> void:
	if count <= 0:
		combo_label.text = ""
		return
	combo_label.text = str(count) + " COMBO" + ("S" if count > 1 else "") + " !"
	combo_label.scale = Vector2(1.4, 1.4)
	combo_label.pivot_offset = combo_label.size / 2.0
	var tw := create_tween()
	tw.tween_property(combo_label, "scale", Vector2.ONE, 0.25)\
	  .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# --- ÉCRAN DE FIN DE COMBAT ---
# Fond sombre + panneau centré : titre, récompenses (lisibles), boutons.
func show_result(victory: bool, extra_text := "") -> void:
	var vp := get_viewport().get_visible_rect().size
	combo_label.text = ""
	result_label.visible = false

	# Fond sombre plein écran (bloque aussi les clics sur le plateau)
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.position = Vector2.ZERO
	overlay.size = vp
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	# Panneau centré
	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(UIStyle.COL_DARK, 0.97)
	ps.set_corner_radius_all(24)
	ps.set_border_width_all(4)
	ps.border_color = UIStyle.COL_GOLD if victory else UIStyle.COL_RED
	ps.shadow_color = Color(0, 0, 0, 0.6)
	ps.shadow_size = 20
	ps.content_margin_left = 40
	ps.content_margin_right = 40
	ps.content_margin_top = 36
	ps.content_margin_bottom = 36
	panel.add_theme_stylebox_override("panel", ps)
	panel.custom_minimum_size = Vector2(vp.x * 0.8, 0)
	overlay.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	panel.add_child(col)

	# Titre
	var title := Label.new()
	title.text = "🎉 VICTOIRE !" if victory else "💀 DÉFAITE..."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", UIStyle.COL_GOLD if victory else UIStyle.COL_RED)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 10)
	col.add_child(title)

	# Récompenses
	if extra_text != "":
		var sep := HSeparator.new()
		col.add_child(sep)

		var rew_title := Label.new()
		rew_title.text = "Récompenses"
		rew_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rew_title.add_theme_font_size_override("font_size", 30)
		rew_title.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		col.add_child(rew_title)

		var rewards := Label.new()
		rewards.text = extra_text
		rewards.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rewards.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # passe à la ligne si trop long
		rewards.add_theme_font_size_override("font_size", 40)
		rewards.add_theme_color_override("font_color", Color.WHITE)
		rewards.add_theme_color_override("font_outline_color", Color.BLACK)
		rewards.add_theme_constant_override("outline_size", 6)
		rewards.add_theme_constant_override("line_spacing", 8)
		col.add_child(rewards)

	# Espace avant les boutons
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	col.add_child(spacer)

	var is_event := GameManager.game_mode == "event"

	# Niveau suivant (mode Histoire, si victoire et qu'il en reste ; peut changer de monde)
	var nxt := LevelDB.next_level(GameManager.current_world, GameManager.current_level)
	if victory and not is_event and nxt.x > 0:
		var label := "Niveau suivant" if nxt.x == GameManager.current_world else "🌍 Monde suivant"
		col.add_child(UIStyle.menu_button(label, UIStyle.COL_GREEN, func():
			GameManager.start_level(nxt.x, nxt.y)
			get_tree().change_scene_to_file("res://scenes/Main.tscn")))

	# Rejouer : relance l'event en mode Event, sinon le même niveau
	col.add_child(UIStyle.menu_button("Rejouer l'event" if is_event else "Rejouer", UIStyle.COL_BLUE, func():
		if is_event:
			GameManager.start_event()
		else:
			GameManager.start_level(GameManager.current_world, GameManager.current_level)
		get_tree().change_scene_to_file("res://scenes/Main.tscn")))

	# Retour au menu
	col.add_child(UIStyle.menu_button("Menu principal", UIStyle.COL_GREY, func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")))

	# Centrage une fois la taille du panneau calculée, puis petite apparition
	await get_tree().process_frame
	panel.size = panel.get_combined_minimum_size()
	panel.position = (vp - panel.size) / 2.0
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.6, 0.6)
	overlay.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(overlay, "modulate:a", 1.0, 0.2)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func rebuild_enemies() -> void:
	for w in enemy_widgets:
		w["root"].queue_free()
	enemy_widgets.clear()
	for e in GameManager.enemies:
		var wd := _make_monster_widget(e, 150, false, true)
		enemy_row.add_child(wd["root"])
		enemy_widgets.append(wd)

# UNE attaque du monstre n°index sur les ennemis 'targets' (MonsterData).
# Attaque de zone = une boule plus grosse vers chaque ennemi.
func play_attack(index: int, targets: Array, is_zone: bool) -> void:
	if index >= team_widgets.size():
		return
	var w: Dictionary = team_widgets[index]
	var mon: MonsterData = w["mon"]
	var root: Control = w["root"]
	var from: Vector2 = root.get_global_rect().get_center()
	_hop(root)
	for ew in enemy_widgets:
		if ew["mon"] in targets:
			_shoot(from, ew["root"], Elements.COLORS[mon.element], 60 if is_zone else BALL)
	await get_tree().create_timer(FLIGHT + 0.05).timeout   # attend l'impact
func _alive_enemy_widgets() -> Array:
	var res: Array = []
	for w in enemy_widgets:
		if w["mon"].is_alive():
			res.append(w)
	return res

func _shoot(from: Vector2, target: Control, col: Color, s: int = BALL) -> void:
	var ball := Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = col
	st.set_corner_radius_all(s / 2)
	st.shadow_color = Color(col, 0.6)     # halo lumineux
	st.shadow_size = 12
	ball.add_theme_stylebox_override("panel", st)
	ball.size = Vector2(s, s)
	ball.position = from - ball.size / 2.0
	ball.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ball)

	var to := target.get_global_rect().get_center() - ball.size / 2.0
	var tw := create_tween()
	tw.tween_property(ball, "position", to, FLIGHT)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		ball.queue_free()
		_flash(target))

# Petit saut de l'attaquant
func _hop(node: Control) -> void:
	node.pivot_offset = node.size / 2.0
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector2(1.15, 1.15), 0.08)
	tw.tween_property(node, "scale", Vector2.ONE, 0.12)

# Flash blanc + secousse de l'ennemi touché
func _flash(node: Control) -> void:
	node.pivot_offset = node.size / 2.0
	node.modulate = Color(2.5, 2.5, 2.5)
	var tw := create_tween()
	tw.tween_property(node, "modulate", Color.WHITE, 0.15)
	var tw2 := create_tween()
	tw2.tween_property(node, "scale", Vector2(0.9, 0.9), 0.05)
	tw2.tween_property(node, "scale", Vector2.ONE, 0.1)

# Affiche un texte au centre (nom de compétence...)
func show_text(t: String) -> void:
	combo_label.text = t
	combo_label.scale = Vector2(1.4, 1.4)
	combo_label.pivot_offset = combo_label.size / 2.0
	var tw := create_tween()
	tw.tween_property(combo_label, "scale", Vector2.ONE, 0.25)\
	  .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Animation de compétence : grosse boule vers la cible
func play_skill(index: int, target: MonsterData) -> void:
	var w: Dictionary = team_widgets[index]
	var mon: MonsterData = w["mon"]
	for ew in enemy_widgets:
		if ew["mon"] == target:
			var from: Vector2 = w["root"].get_global_rect().get_center()
			_hop(w["root"])
			_shoot(from, ew["root"], Elements.COLORS[mon.element], 80)
			break
	await get_tree().create_timer(FLIGHT).timeout
