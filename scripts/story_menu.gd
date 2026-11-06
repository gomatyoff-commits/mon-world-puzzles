# story_menu.gd  -> menu du mode Histoire : choix du MONDE, puis du NIVEAU
# Mondes et niveaux se débloquent dans l'ordre (GameManager.is_level_unlocked).
extends Control

var content: VBoxContainer     # zone qui change (mondes ou niveaux)
var subtitle: Label
var back_btn: Button
var shown_world := 0           # 0 = liste des mondes, sinon n° du monde affiché

func _ready() -> void:
	_build()
	_show_worlds()

func _build() -> void:
	var vp := get_viewport_rect().size

	var title := Label.new()
	title.text = "📖 MODE HISTOIRE"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.1)
	title.size = Vector2(vp.x, 70)
	add_child(title)

	subtitle = Label.new()
	subtitle.add_theme_font_size_override("font_size", 30)
	subtitle.add_theme_color_override("font_color", UIStyle.COL_GOLD)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(0, vp.y * 0.1 + 80)
	subtitle.size = Vector2(vp.x, 50)
	add_child(subtitle)

	# Liste défilante (s'il y a beaucoup de mondes / niveaux)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(vp.x * 0.15, vp.y * 0.25)
	scroll.size = Vector2(vp.x * 0.7, vp.y * 0.6)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 22)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	back_btn = UIStyle.back_button(_on_back)
	back_btn.position = Vector2(30, vp.y - 90)
	add_child(back_btn)

func _clear() -> void:
	for c in content.get_children():
		c.queue_free()

# --- Écran 1 : les mondes ---
func _show_worlds() -> void:
	shown_world = 0
	_clear()
	subtitle.text = "Choisis un monde"
	for w in range(1, LevelDB.world_count() + 1):
		var nb := LevelDB.level_count(w)
		if GameManager.is_world_unlocked(w):
			var done := GameManager.cleared_count(w)
			var txt := "🌍 Monde %d — %s\n%d / %d niveaux terminés" % [w, LevelDB.world_name(w), done, nb]
			if done >= nb:
				txt += "  ✅"
			var col := UIStyle.COL_GREEN if done >= nb else UIStyle.COL_BLUE
			var btn := UIStyle.menu_button(txt, col, _show_levels.bind(w))
			btn.custom_minimum_size = Vector2(0, 110)
			content.add_child(btn)
		else:
			var btn := _locked_button("🔒 Monde %d — ???\nTermine le monde %d" % [w, w - 1])
			btn.custom_minimum_size = Vector2(0, 110)
			content.add_child(btn)

# --- Écran 2 : les niveaux d'un monde ---
func _show_levels(world: int) -> void:
	shown_world = world
	_clear()
	subtitle.text = "Monde %d — %s" % [world, LevelDB.world_name(world)]
	for l in range(1, LevelDB.level_count(world) + 1):
		if GameManager.is_cleared(world, l):
			content.add_child(UIStyle.menu_button("Niveau %d  ✅" % l, UIStyle.COL_GREEN, _on_level_pressed.bind(world, l)))
		elif GameManager.is_level_unlocked(world, l):
			content.add_child(UIStyle.menu_button("Niveau %d" % l, UIStyle.COL_BLUE, _on_level_pressed.bind(world, l)))
		else:
			content.add_child(_locked_button("🔒 Niveau %d" % l))

# Bouton grisé, non cliquable
func _locked_button(txt: String) -> Button:
	var b := UIStyle.menu_button(txt, UIStyle.COL_GREY, func(): pass)
	b.disabled = true
	var st := StyleBoxFlat.new()
	st.bg_color = UIStyle.COL_GREY.darkened(0.4)
	st.set_corner_radius_all(10)
	st.content_margin_left = 18
	st.content_margin_right = 18
	st.content_margin_top = 12
	st.content_margin_bottom = 12
	b.add_theme_stylebox_override("disabled", st)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.45))
	return b

func _on_level_pressed(world: int, level: int) -> void:
	if not GameManager.is_level_unlocked(world, level):
		return
	GameManager.start_level(world, level)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

# Retour : niveaux -> mondes -> menu principal
func _on_back() -> void:
	if shown_world > 0:
		_show_worlds()
	else:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
