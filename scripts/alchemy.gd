extends Control

func _ready() -> void:
	var vp := get_viewport_rect().size

	var title := Label.new()
	title.text = "⚗️ ALCHIMIE"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 40)
	title.size = Vector2(vp.x, 60)
	add_child(title)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 22)
	col.position = Vector2(vp.x * 0.15, vp.y * 0.32)
	col.size = Vector2(vp.x * 0.7, vp.y * 0.4)
	add_child(col)

	_add(col, "⬆️ Monter de niveau", UIStyle.COL_RED,  "res://scenes/FusionMenu.tscn")
	_add(col, "🔮 Évolution",        UIStyle.COL_GOLD, "res://scenes/EvolutionMenu.tscn")
	_add(col, "🎒 Inventaire",       UIStyle.COL_BLUE, "res://scenes/InventoryMenu.tscn")

	var back := UIStyle.back_button(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	back.position = Vector2(30, vp.y - 80)
	add_child(back)

func _add(col: VBoxContainer, title: String, color: Color, scene: String) -> void:
	var b := UIStyle.menu_button(title, color, func():
		get_tree().change_scene_to_file(scene))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(b)
