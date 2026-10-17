extends Control

var _info: Label
var _slots_box: VBoxContainer
var _feedback: Label
var _picker: Control = null

func _ready() -> void:
	var vp := get_viewport_rect().size
	GameManager.update_mine()

	var title := Label.new()
	title.text = "⛏️ MINE À GEMMES"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 90)
	title.size = Vector2(vp.x, 55)
	add_child(title)

	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 24)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.position = Vector2(0, 155)
	_info.size = Vector2(vp.x, 120)
	add_child(_info)

	var collect := UIStyle.menu_button("📥 Collecter", UIStyle.COL_GREEN, _collect)
	collect.position = Vector2(vp.x * 0.1, 295)
	collect.size = Vector2(vp.x * 0.37, 64)
	add_child(collect)

	var upg := UIStyle.menu_button("⬆️ Stockage", UIStyle.COL_BLUE, _upgrade)
	upg.position = Vector2(vp.x * 0.53, 295)
	upg.size = Vector2(vp.x * 0.37, 64)
	add_child(upg)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(vp.x * 0.08, 385)
	scroll.size = Vector2(vp.x * 0.84, vp.y - 565)
	add_child(scroll)
	_slots_box = VBoxContainer.new()
	_slots_box.add_theme_constant_override("separation", 14)
	_slots_box.custom_minimum_size = Vector2(vp.x * 0.84, 0)
	scroll.add_child(_slots_box)

	_feedback = Label.new()
	_feedback.add_theme_font_size_override("font_size", 22)
	_feedback.add_theme_color_override("font_color", UIStyle.COL_GOLD)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.position = Vector2(0, vp.y - 150)
	_feedback.size = Vector2(vp.x, 40)
	add_child(_feedback)

	var back := UIStyle.back_button(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	back.position = Vector2(30, vp.y - 80)
	add_child(back)

	add_child(UIHeader.make(vp))

	var timer := Timer.new()
	timer.wait_time = 5.0
	timer.autostart = true
	timer.timeout.connect(func():
		GameManager.update_mine()
		_refresh())
	add_child(timer)

	_refresh()

func _refresh() -> void:
	var gm := GameManager
	var rate := gm.mine_rate()
	var pct := int(gm.mine_progress / gm.GEM_COST * 100.0)
	var eta := "—"
	if rate > 0:
		eta = "%d min" % int(ceil((gm.GEM_COST - gm.mine_progress) / float(rate)))
	_info.text = "Stockage : 💎 %d / %d\nVitesse totale : %d pts/min\nProchaine gemme : %d%%  (≈ %s)" % [
		gm.mine_stored, gm.mine_capacity, rate, pct, eta]

	for c in _slots_box.get_children():
		c.queue_free()
	for i in gm.mine_slot_count:
		_slots_box.add_child(_make_slot(i))
	var cost := gm.mine_slot_unlock_cost()
	if cost >= 0:
		_slots_box.add_child(UIStyle.menu_button("🔒 Débloquer emplacement (%d 💎)" % cost, UIStyle.COL_GREY, _unlock_slot))

func _make_slot(i: int) -> Control:
	var gm := GameManager
	if i < gm.mine_slots.size():
		var mon: MonsterData = gm.mine_slots[i]
		return UIStyle.menu_button("%s (travail %d) — ❌ Retirer" % [mon.mon_name, mon.work], UIStyle.COL_RED, func():
			gm.mine_remove(mon)
			_refresh())
	return UIStyle.menu_button("➕ Placer un monstre", UIStyle.COL_GREEN, _open_picker)

func _collect() -> void:
	var got := GameManager.collect_mine()
	_feedback.text = "📥 +%d 💎 collectées !" % got if got > 0 else "Rien à collecter pour l'instant."
	_refresh()

func _upgrade() -> void:
	_feedback.text = GameManager.upgrade_mine()
	_refresh()

func _unlock_slot() -> void:
	_feedback.text = GameManager.unlock_mine_slot()
	_refresh()

func _open_picker() -> void:
	var vp := get_viewport_rect().size
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	_picker = overlay

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(vp.x * 0.1, vp.y * 0.2)
	scroll.size = Vector2(vp.x * 0.8, vp.y * 0.55)
	overlay.add_child(scroll)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.custom_minimum_size = Vector2(vp.x * 0.8, 0)
	scroll.add_child(vb)

	var t := Label.new()
	t.text = "Choisis un monstre à envoyer miner"
	t.add_theme_font_size_override("font_size", 24)
	t.add_theme_color_override("font_color", Color.WHITE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)

	for mon in GameManager.collection:
		if GameManager.mine_slots.has(mon):
			continue
		var m := mon
		vb.add_child(UIStyle.menu_button("%s — travail %d/min" % [m.mon_name, m.work], UIStyle.COL_BLUE, func():
			GameManager.mine_add(m)
			_close_picker()
			_refresh()))

	vb.add_child(UIStyle.menu_button("Annuler", UIStyle.COL_GREY, _close_picker))

func _close_picker() -> void:
	if _picker != null:
		_picker.queue_free()
		_picker = null
