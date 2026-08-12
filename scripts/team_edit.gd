extends Control

var status_label: Label
var grid: GridContainer

func _ready() -> void:
	_build()

func _build() -> void:
	var vp := get_viewport_rect().size

	var title := Label.new()
	title.text = "⚔️ ÉDITION D'ÉQUIPE"
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 30)
	title.size = Vector2(vp.x, 60)
	add_child(title)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 26)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.position = Vector2(0, 95)
	status_label.size = Vector2(vp.x, 40)
	add_child(status_label)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(vp.x * 0.05, 150)
	scroll.size = Vector2(vp.x * 0.9, vp.y - 260)
	add_child(scroll)

	grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	_refresh()

	var back := Button.new()
	back.text = "← Retour"
	back.custom_minimum_size = Vector2(180, 56)
	back.position = Vector2(30, vp.y - 80)
	back.pressed.connect(func():
		GameManager.save_game()                                   # ✅ sauve l'équipe choisie
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	add_child(back)

func _refresh() -> void:
	for c in grid.get_children():
		c.queue_free()
	for mon in GameManager.collection:
		grid.add_child(_make_card(mon))
	status_label.text = "Équipe : %d / %d" % [GameManager.team.size(), GameManager.MAX_TEAM]

func _make_card(mon: MonsterData) -> Control:
	var in_team: bool = GameManager.team.has(mon)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 260)
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.15, 0.15, 0.2)
	pstyle.set_corner_radius_all(10)
	pstyle.set_border_width_all(4)
	pstyle.border_color = Color(0.3, 0.9, 0.4) if in_team else Color(0.3, 0.3, 0.35)
	panel.add_theme_stylebox_override("panel", pstyle)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)

	var img := TextureRect.new()
	img.texture = mon.texture
	img.custom_minimum_size = Vector2(0, 90)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.modulate = Elements.COLORS[mon.element]     # retire si vrais PNG
	vb.add_child(img)

	var name_lbl := Label.new()
	name_lbl.text = mon.mon_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(name_lbl)

	var lvl_lbl := Label.new()
	lvl_lbl.text = "Nv %d   %s" % [mon.level, Elements.NAMES[mon.element]]
	lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(lvl_lbl)

	var stat_lbl := Label.new()
	stat_lbl.text = "PV %d  ATK %d" % [mon.max_hp, mon.atk]
	stat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(stat_lbl)

	# barre d'XP
	var xp_bar := ProgressBar.new()
	xp_bar.show_percentage = false
	xp_bar.max_value = mon.xp_to_next()
	xp_bar.value = mon.xp
	xp_bar.custom_minimum_size = Vector2(0, 12)
	vb.add_child(xp_bar)

	# bouton ajouter / retirer
	var btn := Button.new()
	btn.text = "Retirer" if in_team else "Ajouter"
	btn.pressed.connect(_toggle.bind(mon))
	vb.add_child(btn)

	return panel

func _toggle(mon: MonsterData) -> void:
	if GameManager.team.has(mon):
		GameManager.team.erase(mon)
	elif GameManager.team.size() < GameManager.MAX_TEAM:
		GameManager.team.append(mon)
	GameManager.team_hp = GameManager.team_max_hp()   # recalcule le pool
	_refresh()
