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
	var border := Color(0.3, 0.9, 0.4) if in_team else UICards.BORDER_OFF
	var c := UICards.card(border, Vector2(180, 260))
	var vb: VBoxContainer = c[1]

	vb.add_child(UICards.image(mon))
	vb.add_child(UICards.label(mon.mon_name))
	vb.add_child(UICards.label("Nv %d   %s" % [mon.level, Elements.NAMES[mon.element]]))
	vb.add_child(UICards.label("PV %d  ATK %d" % [mon.max_hp, mon.atk]))
	vb.add_child(UICards.label("PV %d  ATK %d  DEF %d" % [mon.max_hp, mon.atk, mon.defense]))

	var xp_bar := ProgressBar.new()
	xp_bar.show_percentage = false
	xp_bar.max_value = mon.xp_to_next()
	xp_bar.value = mon.xp
	xp_bar.custom_minimum_size = Vector2(0, 12)
	vb.add_child(xp_bar)

	var btn := Button.new()
	btn.text = "Retirer" if in_team else "Ajouter"
	btn.pressed.connect(_toggle.bind(mon))
	vb.add_child(btn)

	return c[0]

func _toggle(mon: MonsterData) -> void:
	if GameManager.team.has(mon):
		GameManager.team.erase(mon)
	elif GameManager.team.size() < GameManager.MAX_TEAM:
		GameManager.team.append(mon)
	GameManager.team_hp = GameManager.team_max_hp()   # recalcule le pool
	_refresh()
