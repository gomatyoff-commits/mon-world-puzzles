extends Control

var base_mon: MonsterData = null
var selected_rec: Dictionary = {}
var fodder: Array = []
var evo_popup: Control = null

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
	elif selected_rec.is_empty():
		info_label.text = "Choisis une évolution"
		evolve_btn.disabled = true
	else:
		var err := GameManager.can_evolve(base_mon, selected_rec, fodder)
		info_label.text = "%s → %s\nNv %d/%d · Sacrifices %d/%d · %s\n%s" % [
			base_mon.mon_name, selected_rec["to"],
			base_mon.level, selected_rec["min_level"],
			fodder.size(), selected_rec["fodder"],
			GameManager.MATERIALS[selected_rec["material"]],
			("✅ Prêt !" if err == "" else "❌ " + err)]
		evolve_btn.disabled = (err != "")

func _make_card(mon: MonsterData) -> Control:
	var border := Color(0.6, 0.4, 1.0) if mon == base_mon \
		else (Color(0.9, 0.3, 0.3) if fodder.has(mon) else UICards.BORDER_OFF)
	var c := UICards.tappable_card(border, Vector2(180, 170), _on_card.bind(mon))
	var vb: VBoxContainer = c[1]
	vb.add_child(UICards.image(mon, 80))
	vb.add_child(UICards.label("%s\nRang %d · Nv %d" % [mon.mon_name, mon.rank, mon.level]))
	return c[0]

func _on_card(mon: MonsterData) -> void:
	if base_mon == null:
		# 1er clic : ouvre le menu de choix d'évolution
		if GameManager.get_evolutions(mon).is_empty():
			info_label.text = "%s ne peut pas évoluer." % mon.mon_name
			return
		_open_evo_popup(mon)
	elif mon == base_mon:
		# re-clic sur la base : désélectionne
		base_mon = null
		selected_rec = {}
		fodder.clear()
		_refresh()
	else:
		# les autres cartes = sacrifices
		if fodder.has(mon):
			fodder.erase(mon)
		else:
			fodder.append(mon)
		_refresh()

# --- MENU DE CHOIX D'ÉVOLUTION (popup) ---
func _open_evo_popup(mon: MonsterData) -> void:
	var vp := get_viewport_rect().size

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	evo_popup = overlay

	var panel := PanelContainer.new()
	panel.position = Vector2(vp.x * 0.1, vp.y * 0.2)
	panel.custom_minimum_size = Vector2(vp.x * 0.8, 0)
	overlay.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)

	var t := Label.new()
	t.text = "Évolutions de " + mon.mon_name
	t.add_theme_font_size_override("font_size", 26)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)

	for rec in GameManager.get_evolutions(mon):
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 64)
		b.text = "→ %s   (Nv %d · %d slimes · %s)" % [
			rec["to"], rec["min_level"], rec["fodder"], GameManager.MATERIALS[rec["material"]]]
		b.pressed.connect(_choose_evo.bind(mon, rec))
		vb.add_child(b)

	var cancel := Button.new()
	cancel.text = "Annuler"
	cancel.custom_minimum_size = Vector2(0, 56)
	cancel.pressed.connect(_close_popup)
	vb.add_child(cancel)

func _choose_evo(mon: MonsterData, rec: Dictionary) -> void:
	base_mon = mon
	selected_rec = rec
	fodder.clear()
	_close_popup()
	_refresh()

func _close_popup() -> void:
	if evo_popup != null:
		evo_popup.queue_free()
		evo_popup = null

func _do_evolve() -> void:
	if base_mon == null or selected_rec.is_empty():
		return
	var target: String = selected_rec.get("to", "")
	if GameManager.evolve(base_mon, selected_rec, fodder):
		info_label.text = "✨ Évolution réussie → %s !" % target
		base_mon = null
		selected_rec = {}
		fodder.clear()
		_refresh()
