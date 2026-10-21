extends Control

var base_mon: MonsterData = null
var selected_rec: Dictionary = {}
var fodder: Array = []
var evo_popup: Node = null

var info_label: Label
var mat_label: Label
var grid: GridContainer
var evolve_btn: Button

func _ready() -> void:
	_build()

func _build() -> void:
	var vp := get_viewport_rect().size
	add_child(UIHeader.make(vp))

	var title := Label.new()
	title.text = "🔮 ÉVOLUTION"
	title.add_theme_font_size_override("font_size", 38)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 85)
	title.size = Vector2(vp.x, 50)
	add_child(title)

	mat_label = Label.new()
	mat_label.add_theme_font_size_override("font_size", 20)
	mat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mat_label.position = Vector2(0, 130)
	mat_label.size = Vector2(vp.x, 30)
	add_child(mat_label)

	info_label = Label.new()
	info_label.add_theme_font_size_override("font_size", 20)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.position = Vector2(0, 165)
	info_label.size = Vector2(vp.x, 70)
	add_child(info_label)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(vp.x * 0.05, 235)
	scroll.size = Vector2(vp.x * 0.9, vp.y - 390)
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
		get_tree().change_scene_to_file("res://scenes/AlchemyMenu.tscn"))
	add_child(back)

	_refresh()

func _refresh() -> void:
	for c in grid.get_children():
		c.queue_free()
	for mon in GameManager.collection:
		if base_mon == null:
			if GameManager.is_working(mon):
				continue
		else:
			if mon != base_mon and GameManager.is_busy(mon):
				continue
		grid.add_child(_make_card(mon))

	var mats: Array[String] = []
	for id in GameManager.materials.keys():
		if int(GameManager.materials[id]) > 0:
			mats.append("%s x%d" % [LootDB.MATERIALS[id], GameManager.materials[id]])
	mat_label.text = "Matériaux : " + (", ".join(mats) if mats.size() > 0 else "aucun")

	if base_mon == null:
		info_label.text = "Choisis un monstre à faire évoluer"
		evolve_btn.disabled = true
	elif selected_rec.is_empty():
		info_label.text = "Choisis une évolution"
		evolve_btn.disabled = true
	else:
		var err: String = GameManager.can_evolve(base_mon, selected_rec, fodder)
		info_label.text = "%s → %s\nNv %d/%d · Sacrifices %d/%d · %s · 🪙 %d\n%s" % [
			base_mon.mon_name, GameManager.evo_name(selected_rec),
			base_mon.level, selected_rec["min_level"],
			fodder.size(), selected_rec["fodder"],
			LootDB.MATERIALS[selected_rec["material"]],
			GameManager.evolution_cost(base_mon),
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

	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	evo_popup = layer

	var overlay := ColorRect.new()
	overlay.color = Color("#15171e")
	overlay.position = Vector2.ZERO
	overlay.size = vp
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(overlay)

	var t := Label.new()
	t.text = "Évolutions de " + mon.mon_name
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", Color.WHITE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector2(0, vp.y * 0.06)
	t.size = Vector2(vp.x, 55)
	overlay.add_child(t)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(vp.x * 0.08, vp.y * 0.14)
	scroll.size = Vector2(vp.x * 0.84, vp.y * 0.68)
	overlay.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)

	for rec in GameManager.get_evolutions(mon):
		grid.add_child(_evo_card(mon, rec))

	var cancel := UIStyle.menu_button("Annuler", UIStyle.COL_GREY, _close_popup)
	cancel.position = Vector2(vp.x * 0.3, vp.y * 0.86)
	cancel.size = Vector2(vp.x * 0.4, 60)
	overlay.add_child(cancel)

func _evo_card(mon: MonsterData, rec: Dictionary) -> Control:
	var vp := get_viewport_rect().size
	var to_id: String = rec["to_id"]
	var seen := GameManager.is_discovered(to_id)
	var c := UICards.tappable_card(UIStyle.COL_GOLD, Vector2(vp.x * 0.36, 250), _choose_evo.bind(mon, rec))
	var vb: VBoxContainer = c[1]
	vb.add_theme_constant_override("separation", 6)
	vb.add_child(UICards.species_icon(to_id, seen, 110))
	vb.add_child(UICards.label(GameManager.evo_name(rec) if seen else "???", 22))
	vb.add_child(UICards.label("Nv %d requis" % rec["min_level"], 18))
	vb.add_child(UICards.label("%d sacrifice(s)" % rec["fodder"], 16))
	vb.add_child(UICards.label(LootDB.MATERIALS[rec["material"]], 16))
	return c[0]

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
	var target: String = GameManager.evo_name(selected_rec)
	if GameManager.evolve(base_mon, selected_rec, fodder):
		info_label.text = "✨ Évolution réussie → %s !" % target
		base_mon = null
		selected_rec = {}
		fodder.clear()
		_refresh()
