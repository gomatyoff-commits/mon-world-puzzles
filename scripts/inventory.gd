extends Control

func _ready() -> void:
	var vp := get_viewport_rect().size

	var title := Label.new()
	title.text = "🎒 INVENTAIRE"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 30)
	title.size = Vector2(vp.x, 55)
	add_child(title)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(vp.x * 0.1, 110)
	scroll.size = Vector2(vp.x * 0.8, vp.y - 220)
	add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	var any := false
	for id in LootDB.MATERIALS.keys():
		var qty := int(GameManager.materials.get(id, 0))
		if qty <= 0:
			continue
		any = true
		var row := Label.new()
		row.text = "%s  ×%d" % [LootDB.MATERIALS[id], qty]
		row.add_theme_font_size_override("font_size", 26)
		list.add_child(row)

	if not any:
		var empty := Label.new()
		empty.text = "Aucun matériau pour l'instant.\nFarme le Mode Event !"
		empty.add_theme_font_size_override("font_size", 24)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.position = Vector2(0, vp.y * 0.4)
		empty.size = Vector2(vp.x, 80)
		add_child(empty)

	var back := Button.new()
	back.text = "← Retour"
	back.custom_minimum_size = Vector2(160, 56)
	back.position = Vector2(30, vp.y - 80)
	back.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/AlchemyMenu.tscn"))
	add_child(back)
