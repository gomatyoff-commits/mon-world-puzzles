extends Control

var base_mon: MonsterData = null
var fodder: Array = []
var info_label: Label
var grid: GridContainer
var fuse_btn: Button

func _ready() -> void:
	_build()

func _build() -> void:
	var vp := get_viewport_rect().size

	var title := Label.new()
	title.text = "⚗️ ALCHIMIE"
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 20)
	title.size = Vector2(vp.x, 55)
	add_child(title)

	info_label = Label.new()
	info_label.add_theme_font_size_override("font_size", 22)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.position = Vector2(0, 80)
	info_label.size = Vector2(vp.x, 50)
	add_child(info_label)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(vp.x * 0.05, 140)
	scroll.size = Vector2(vp.x * 0.9, vp.y - 300)
	add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	fuse_btn = Button.new()
	fuse_btn.text = "Fusionner"
	fuse_btn.custom_minimum_size = Vector2(220, 60)
	fuse_btn.position = Vector2(vp.x / 2 - 110, vp.y - 150)
	fuse_btn.pressed.connect(_do_fusion)
	add_child(fuse_btn)

	var back := Button.new()
	back.text = "← Retour"
	back.custom_minimum_size = Vector2(160, 56)
	back.position = Vector2(30, vp.y - 80)
	back.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	add_child(back)

	_refresh()

func _refresh() -> void:
	for c in grid.get_children():
		c.queue_free()
	for mon in GameManager.collection:
		grid.add_child(_make_card(mon))

	if base_mon == null:
		info_label.text = "Choisis le monstre à FAIRE ÉVOLUER (or)"
		fuse_btn.disabled = true
	else:
		var gain := 0
		for f in fodder: gain += f.fusion_value()
		info_label.text = "%s Nv %d  →  +%d XP  (%d sacrifice(s))" % [base_mon.mon_name, base_mon.level, gain, fodder.size()]
		fuse_btn.disabled = fodder.is_empty()

func _make_card(mon: MonsterData) -> Control:
	var border := Color(0.95, 0.8, 0.2) if mon == base_mon \
		else (Color(0.9, 0.3, 0.3) if fodder.has(mon) else UICards.BORDER_OFF)
	var c := UICards.tappable_card(border, Vector2(180, 160), _on_card.bind(mon))
	var vb: VBoxContainer = c[1]
	vb.add_child(UICards.image(mon))
	vb.add_child(UICards.label("%s\nNv %d" % [mon.mon_name, mon.level]))
	return c[0]

func _on_card(mon: MonsterData) -> void:
	if base_mon == null:
		base_mon = mon                      # 1er clic = base
	elif mon == base_mon:
		base_mon = null                     # re-clic = désélectionne la base
		fodder.clear()
	elif fodder.has(mon):
		fodder.erase(mon)                   # retire du sacrifice
	else:
		fodder.append(mon)                  # ajoute au sacrifice
	_refresh()

func _do_fusion() -> void:
	if base_mon == null or fodder.is_empty():
		return
	var gained := GameManager.fuse(base_mon, fodder)
	info_label.text = "✨ +%d XP ! %s est Nv %d" % [gained, base_mon.mon_name, base_mon.level]
	fodder.clear()
	_refresh()
