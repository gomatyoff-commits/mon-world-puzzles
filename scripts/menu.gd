extends Control

const TABS := [
	{"label": "Histoire",  "icon": "📖", "scene": "res://scenes/StoryMenu.tscn"},
	{"label": "Event",     "icon": "🎉", "scene": "res://scenes/EventMenu.tscn"},
	{"label": "Équipe",    "icon": "⚔️", "scene": "res://scenes/TeamEdit.tscn"},
	{"label": "Alchimie",  "icon": "⚗️", "scene": "res://scenes/AlchemyMenu.tscn"},
	{"label": "Mine",      "icon": "⛏️", "scene": "res://scenes/MineMenu.tscn"},
	{"label": "Boutique",  "icon": "🛒", "scene": "res://scenes/ShopMenu.tscn"},
]

const MON_SIZE := 110.0   # taille d'un monstre à l'écran
const SPEED := 60.0       # vitesse de marche (pixels/seconde)
const BAR_H := 92.0       # hauteur de la barre d'onglets

var zone: Control
var walkers: Array = []

func _ready() -> void:
	_build()

func _build() -> void:
	var vp := get_viewport_rect().size

	# Titre centré en haut
	var title := Label.new()
	title.text = "MonWorld Puzzle"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.12)
	title.size = Vector2(vp.x, 60)
	add_child(title)

	# Zone de balade : sous le titre, au-dessus de la barre du bas
	_build_wander_zone(vp, vp.y * 0.12 + 70, vp.y - BAR_H)

	_build_bottom_bar(vp)

	add_child(UIHeader.make(vp))

func _build_bottom_bar(vp: Vector2) -> void:
	var bar_h := 92.0
	var top := vp.y - bar_h

	# fond de la barre
	var bg := Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color("#1e2128")
	st.border_width_top = 3
	st.border_color = Color("#3a3f4a")
	bg.add_theme_stylebox_override("panel", st)
	bg.position = Vector2(0, top)
	bg.size = Vector2(vp.x, bar_h)
	add_child(bg)

	# rangée d'onglets
	var row := HBoxContainer.new()
	row.position = Vector2(0, top)
	row.size = Vector2(vp.x, bar_h)
	add_child(row)

	for tab in TABS:
		row.add_child(_make_tab(tab))

func _make_tab(tab: Dictionary) -> Control:
	var btn := Button.new()
	btn.flat = true
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 92)

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	btn.add_child(vb)

	var icon := Label.new()
	icon.text = tab["icon"]
	icon.add_theme_font_size_override("font_size", 26)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(icon)

	var lbl := Label.new()
	lbl.text = tab["label"]
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(lbl)

	var scene: String = tab["scene"]
	if scene == "":
		btn.disabled = true            # onglet "Plus tard" désactivé
		vb.modulate = Color(1, 1, 1, 0.4)
	else:
		btn.pressed.connect(func(): get_tree().change_scene_to_file(scene))

	return btn

func _build_wander_zone(vp: Vector2, top: float, bottom: float) -> void:
	zone = Control.new()
	zone.position = Vector2(0, top)
	zone.size = Vector2(vp.x, bottom - top)
	zone.clip_contents = true                       # rien ne dépasse de la zone
	zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(zone)

	for mon in GameManager.team:
		if mon == null:
			continue
		var tr := TextureRect.new()
		tr.texture = mon.texture
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.size = Vector2(MON_SIZE, MON_SIZE)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var start := _random_point()
		tr.position = start
		zone.add_child(tr)
		walkers.append({
			"node": tr,
			"pos": start,
			"target": _random_point(),
			"wait": randf_range(0.0, 1.5),
			"t": randf() * TAU,
		})

func _random_point() -> Vector2:
	return Vector2(
		randf_range(0.0, zone.size.x - MON_SIZE),
		randf_range(10.0, zone.size.y - MON_SIZE))

func _process(delta: float) -> void:
	for w in walkers:
		var n: TextureRect = w["node"]
		# Pause : le monstre reste immobile un moment
		if w["wait"] > 0.0:
			w["wait"] -= delta
			n.position = w["pos"]
			continue

		var to: Vector2 = w["target"] - w["pos"]
		var step := SPEED * delta
		if to.length() <= step:
			# Arrivé : petite pause puis nouvelle destination
			w["pos"] = w["target"]
			w["target"] = _random_point()
			w["wait"] = randf_range(1.0, 3.0)
		else:
			w["pos"] += to.normalized() * step
			n.flip_h = to.x < 0                 # regarde dans le sens de la marche

		# Petit sautillement pendant la marche
		w["t"] += delta * 10.0
		n.position = w["pos"] + Vector2(0, -absf(sin(w["t"])) * 8.0)
