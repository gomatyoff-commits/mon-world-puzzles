extends Control

var base_mon: MonsterData = null
var fodder: Array = []
var info_label: Label
var mat_label: Label
var grid: GridContainer
var evolve_btn: Button

func _ready() -> void:
	_build()

func _build() -> void:
	var vp := get_viewport_rect().size

	var title := Label.new()
	title.text = "🔮 ÉVOLUTION"
	title.add_theme_font_size_override("font_size", 38)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 15)
	title.size = Vector2(vp.x, 50)
	add_child(title)

	mat_label = Label.new()
	mat_label.add_theme_font_size_override("font_size", 20)
	mat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mat_label.position = Vector2(0, 65)
	mat_label.size = Vector2(vp.x, 30)
	add_child(mat_label)

	info_label = Label.new()
	info_label.add_theme_font_size_override("font_size", 20)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.position = Vector2(0, 100)
	info_label.size = Vector2(vp.x, 70)
	add_child(info_label)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(vp.x * 0.05, 175)
	scroll.size = Vector2(vp.x * 0.9, vp.y - 330)
	add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	evolve_btn = Button.new()
	evolve_btn.text = "Évoluer"
	evolve_btn.custom_minimum_size = Vector2(220, 60)
	evolve_btn.position = Vector2(vp.x / 2 - 110, vp.y - 150)
	evolve_btn.pressed.connect(_do_evolve)
	add_child(evolve_btn)

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

	var mats: Array[String] = []
	for id in GameManager.materials.keys():
		if int(GameManager.materials[id]) > 0:
			mats.append("%s x%d" % [GameManager.MATERIALS[id], GameManager.materials[id]])
	mat_label.text = "Matériaux : " + (", ".join(mats) if mats.size() > 0 else "aucun")

	if base_mon == null:
		info_label.text = "Choisis un monstre à faire évoluer"
		evolve_btn.disabled = true
	else:
		var rec := GameManager.get_evolution(base_mon)
		if rec.is_empty():
			info_label.text = "%s ne peut pas évoluer." % base_mon.mon_name
			evolve_btn.disabled = true
		else:
			var err := GameManager.can_evolve(base_mon, fodder)
			info_label.text = "%s → %s\nNv %d/%d · Sacrifices %d/%d · %s\n%s" % [
				base_mon.mon_name, rec["to"],
				base_mon.level, rec["min_level"],
				fodder.size(), rec["fodder"],
				GameManager.MATERIALS[rec["material"]],
				("✅ Prêt !" if err == "" else "❌ " + err)]
			evolve_btn.disabled = (err != "")

func _make_card(mon: MonsterData) -> Control:
	var is_base: bool = (mon == base_mon)
	var is_fodder: bool = fodder.has(mon)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 160)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.15, 0.15, 0.2)
	st.set_corner_radius_all(10)
	st.set_border_width_all(4)
	st.border_color = Color(0.6, 0.4, 1.0) if is_base else (Color(0.9, 0.3, 0.3) if is_fodder else Color(0.3, 0.3, 0.35))
	panel.add_theme_stylebox_override("panel", st)

	var btn := Button.new()
	btn.flat = true
	btn.pressed.connect(_on_card.bind(mon))
	panel.add_child(btn)

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vb)

	var img := TextureRect.new()
	img.texture = mon.texture
	img.custom_minimum_size = Vector2(0, 80)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vb.add_child(img)

	var lbl := Label.new()
	lbl.text = "%s\nRang %d · Nv %d" % [mon.mon_name, mon.rank, mon.level]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(lbl)

	return panel

func _on_card(mon: MonsterData) -> void:
	if base_mon == null:
		base_mon = mon
	elif mon == base_mon:
		base_mon = null
		fodder.clear()
	elif fodder.has(mon):
		fodder.erase(mon)
	else:
		fodder.append(mon)
	_refresh()

func _do_evolve() -> void:
	if base_mon == null:
		return
	var target: String = GameManager.get_evolution(base_mon).get("to", "")
	if GameManager.evolve(base_mon, fodder):
		info_label.text = "✨ Évolution réussie → %s !" % target
		base_mon = null
		fodder.clear()
		_refresh()
