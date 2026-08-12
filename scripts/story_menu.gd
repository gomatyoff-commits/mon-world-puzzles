extends Control

func _ready() -> void:
	_build()

func _build() -> void:
	var vp := get_viewport_rect().size

	var title := Label.new()
	title.text = "📖 MODE HISTOIRE"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.1)
	title.size = Vector2(vp.x, 70)
	add_child(title)

	# Boutons de niveaux
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 22)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.position = Vector2(vp.x * 0.25, vp.y * 0.28)
	col.size = Vector2(vp.x * 0.5, vp.y * 0.5)
	add_child(col)

	for i in range(1, GameManager.NB_LEVELS + 1):
		var btn := Button.new()
		btn.text = "Niveau " + str(i)
		btn.custom_minimum_size = Vector2(0, 70)
		btn.add_theme_font_size_override("font_size", 30)
		btn.pressed.connect(_on_level_pressed.bind(i))
		col.add_child(btn)

	# Bouton retour
	_add_back_button()

func _on_level_pressed(level: int) -> void:
	GameManager.start_level(level)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _add_back_button() -> void:
	var vp := get_viewport_rect().size
	var back := Button.new()
	back.text = "← Retour"
	back.custom_minimum_size = Vector2(160, 56)
	back.position = Vector2(30, vp.y - 90)
	back.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	add_child(back)
