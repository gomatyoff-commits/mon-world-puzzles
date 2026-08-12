# ui_cards.gd — helpers réutilisables pour les cartes de monstres
extends RefCounted
class_name UICards

const BG := Color(0.15, 0.15, 0.2)
const BORDER_OFF := Color(0.3, 0.3, 0.35)

static func _panel(border: Color, min_size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = min_size
	var st := StyleBoxFlat.new()
	st.bg_color = BG
	st.set_corner_radius_all(10)
	st.set_border_width_all(4)
	st.border_color = border
	p.add_theme_stylebox_override("panel", st)
	return p

# Carte simple (contenu direct). Retourne [panel, vbox]
static func card(border: Color, min_size: Vector2) -> Array:
	var p := _panel(border, min_size)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	p.add_child(vb)
	return [p, vb]

# Carte entièrement cliquable. Retourne [panel, vbox]
static func tappable_card(border: Color, min_size: Vector2, on_press: Callable) -> Array:
	var p := _panel(border, min_size)
	var btn := Button.new()
	btn.flat = true
	btn.pressed.connect(on_press)
	p.add_child(btn)
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vb)
	return [p, vb]

static func image(mon: MonsterData, h := 90) -> TextureRect:
	var img := TextureRect.new()
	img.texture = mon.texture
	img.custom_minimum_size = Vector2(0, h)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return img

static func label(text: String, font_size := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_size > 0:
		l.add_theme_font_size_override("font_size", font_size)
	return l
