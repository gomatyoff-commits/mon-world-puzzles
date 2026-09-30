extends Control

const TABS := [
	{"label": "Histoire",  "icon": "📖", "scene": "res://scenes/StoryMenu.tscn"},
	{"label": "Event",     "icon": "🎉", "scene": "res://scenes/EventMenu.tscn"},
	{"label": "Équipe",    "icon": "⚔️", "scene": "res://scenes/TeamEdit.tscn"},
	{"label": "Alchimie",  "icon": "⚗️", "scene": "res://scenes/AlchemyMenu.tscn"},
	{"label": "Plus tard", "icon": "❔", "scene": ""},
	{"label": "Plus tard", "icon": "❔", "scene": ""},
]

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

	_build_bottom_bar(vp)

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
