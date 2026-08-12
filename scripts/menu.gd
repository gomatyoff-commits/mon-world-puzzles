extends Control

func _ready() -> void:
	_build_menu()

func _build_menu() -> void:
	var vp := get_viewport_rect().size

	# --- Titre ---
	var title := Label.new()
	title.text = "🐉 PUZZLE DRAGONS"
	title.add_theme_font_size_override("font_size", 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.12)
	title.size = Vector2(vp.x, 80)
	add_child(title)

	# --- Colonne de modes ---
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 28)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.position = Vector2(vp.x * 0.2, vp.y * 0.35)
	col.size = Vector2(vp.x * 0.6, vp.y * 0.5)
	add_child(col)

	_add_mode(col, "📖 Mode Histoire", "res://scenes/StoryMenu.tscn")
	_add_mode(col, "🎉 Mode Event",    "res://scenes/EventMenu.tscn")
	_add_mode(col, "⚔️ Édition d'équipe", "res://scenes/TeamEdit.tscn")
	_add_mode(col, "⚗️ Alchimie",       "res://scenes/AlchemyMenu.tscn")

func _add_mode(col: VBoxContainer, label: String, scene_path: String) -> void:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 80)
	btn.add_theme_font_size_override("font_size", 30)
	btn.pressed.connect(func():
		var err := get_tree().change_scene_to_file(scene_path)
		if err != OK:
			print("❌ Échec chargement : ", scene_path, " (code ", err, ")"))
	col.add_child(btn)
