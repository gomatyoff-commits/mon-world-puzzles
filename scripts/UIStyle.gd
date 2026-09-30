class_name UIStyle
extends RefCounted

# ---- COULEURS ----
const COL_RED   := Color("#e74c3c")
const COL_GOLD  := Color("#f1c40f")
const COL_BLUE  := Color("#3498db")
const COL_GREEN := Color("#2ecc71")
const COL_GREY  := Color("#7f8c8d")
const COL_DARK  := Color("#2c3e50")

# ---- STYLEBOX INTERNE ----
static func _make_style(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb

# ---- BOUTON DE MENU ----
static func menu_button(title: String, color: Color, callback: Callable) -> Button:
	var b := Button.new()
	b.text = title
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _make_style(color))
	b.add_theme_stylebox_override("hover", _make_style(color.lightened(0.15)))
	b.add_theme_stylebox_override("pressed", _make_style(color.darkened(0.2)))
	b.custom_minimum_size = Vector2(0, 60)
	b.pressed.connect(callback)
	return b

# ---- BOUTON RETOUR ----
static func back_button(callback: Callable) -> Button:
	var b := Button.new()
	b.text = "⬅ Retour"
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _make_style(COL_GREY))
	b.add_theme_stylebox_override("hover", _make_style(COL_GREY.lightened(0.15)))
	b.add_theme_stylebox_override("pressed", _make_style(COL_GREY.darkened(0.2)))
	b.custom_minimum_size = Vector2(140, 50)
	b.pressed.connect(callback)
	return b
