extends Control

func _ready() -> void:
	var vp := get_viewport_rect().size

	var title := Label.new()
	title.text = "🎉 MODE EVENT\nInvasion de Slimes"
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.15)
	title.size = Vector2(vp.x, 140)
	add_child(title)

	var info := Label.new()
	info.text = "3 vagues de slimes\n1 chance sur 4 d'obtenir un slime !"
	info.add_theme_font_size_override("font_size", 24)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.position = Vector2(0, vp.y * 0.35)
	info.size = Vector2(vp.x, 80)
	add_child(info)

	var play := Button.new()
	play.text = "Lancer l'Event"
	play.custom_minimum_size = Vector2(260, 70)
	play.add_theme_font_size_override("font_size", 30)
	play.position = Vector2(vp.x / 2 - 130, vp.y * 0.55)
	play.pressed.connect(func():
		GameManager.start_event()
		get_tree().change_scene_to_file("res://scenes/Main.tscn"))
	add_child(play)

	var back := Button.new()
	back.text = "← Retour"
	back.custom_minimum_size = Vector2(160, 56)
	back.position = Vector2(30, vp.y - 90)
	back.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	add_child(back)
