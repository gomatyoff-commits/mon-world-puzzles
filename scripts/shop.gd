extends Control

var _gems_label: Label
var _feedback: Label

func _ready() -> void:
	var vp := get_viewport_rect().size

	var title := Label.new()
	title.text = "🛒 BOUTIQUE"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 90)
	title.size = Vector2(vp.x, 60)
	add_child(title)

	# Bandeau monnaies
	_gems_label = Label.new()
	_gems_label.add_theme_font_size_override("font_size", 28)
	_gems_label.add_theme_color_override("font_color", UIStyle.COL_GOLD)
	_gems_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gems_label.position = Vector2(0, 165)
	_gems_label.size = Vector2(vp.x, 40)
	add_child(_gems_label)

	# Carte article : Slime Rang 0
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 14)
	card.position = Vector2(vp.x * 0.2, vp.y * 0.28)
	card.size = Vector2(vp.x * 0.6, vp.y * 0.35)
	add_child(card)

	var icon := TextureRect.new()
	icon.texture = load(MonsterDB.species["slime"]["tex"])
	icon.custom_minimum_size = Vector2(0, 140)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.text = "Slime (Rang 0)"
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(name_lbl)

	var buy := UIStyle.menu_button("💎 25 gemmes", UIStyle.COL_GOLD, _buy_slime)
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(buy)

	# Message de retour
	_feedback = Label.new()
	_feedback.add_theme_font_size_override("font_size", 24)
	_feedback.add_theme_color_override("font_color", UIStyle.COL_GREEN)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.position = Vector2(0, vp.y * 0.68)
	_feedback.size = Vector2(vp.x, 50)
	add_child(_feedback)

	var back := UIStyle.back_button(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	back.position = Vector2(30, vp.y - 80)
	add_child(back)
	
	add_child(UIHeader.make(vp))

	_refresh()

func _refresh() -> void:
	_gems_label.text = "💎 %d gemmes     🪙 %d pièces" % [GameManager.gems, GameManager.coins]

func _buy_slime() -> void:
	_feedback.text = GameManager.buy_monster("slime", 25)
	_refresh()
