class_name UIHeader
extends RefCounted

const HEIGHT := 72

static func make(vp: Vector2) -> Control:
	var root := Control.new()
	root.position = Vector2.ZERO
	root.size = Vector2(vp.x, HEIGHT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color("#1e2128")
	st.border_width_bottom = 2
	st.border_color = Color("#3a3f4a")
	bg.add_theme_stylebox_override("panel", st)
	bg.size = Vector2(vp.x, HEIGHT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	# Pseudo (à gauche)
	var name_lbl := Label.new()
	name_lbl.text = "👤 " + GameManager.player_name
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.position = Vector2(24, 0)
	name_lbl.size = Vector2(vp.x * 0.5 - 24, HEIGHT)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(name_lbl)

	# Monnaies (à droite)
	var money_lbl := Label.new()
	money_lbl.text = "🪙 %d     💎 %d" % [GameManager.coins, GameManager.gems]
	money_lbl.add_theme_font_size_override("font_size", 24)
	money_lbl.add_theme_color_override("font_color", UIStyle.COL_GOLD)
	money_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	money_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	money_lbl.position = Vector2(vp.x * 0.5, 0)
	money_lbl.size = Vector2(vp.x * 0.5 - 24, HEIGHT)
	money_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(money_lbl)

	return root
