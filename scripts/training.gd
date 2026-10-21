extends Control

var _info: Label
var _slots_box: VBoxContainer
var _feedback: Label
var _upg_btn: Button
var _picker: Node = null

func _ready() -> void:
	var vp := get_viewport_rect().size
	GameManager.update_training()

	var title := Label.new()
	title.text = "🏋️ ENTRAÎNEMENT"
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

	_upg_btn = UIStyle.menu_button("⬆️ Améliorer", UIStyle.COL_BLUE, _upgrade)
	_upg_btn.position = Vector2(vp.x * 0.2, 295)
	_upg_btn.size = Vector2(vp.x * 0.6, 64)
	add_child(_upg_btn)

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
		get_tree().change_scene_to_file("res://scenes/AlchemyMenu.tscn"))
	back.position = Vector2(30, vp.y - 80)
	add_child(back)

	add_child(UIHeader.make(vp))

	var timer := Timer.new()
	timer.wait_time = 5.0
	timer.autostart = true
	timer.timeout.connect(func():
		GameManager.update_training()
		_refresh())
	add_child(timer)

	_refresh()

func _refresh() -> void:
	var gm := GameManager
	_info.text = "Niveau du centre : %d / %d\nGain : %d XP / heure par monstre\nEmplacements : %d / %d" % [
		gm.training_level, gm.TRAIN_MAX_LEVEL, gm.training_rate(),
		gm.training_slot_count, gm.TRAIN_MAX_SLOTS]

	var cost := gm.training_upgrade_cost()
	_upg_btn.text = ("⬆️ Améliorer (%d 💎)" % cost) if cost >= 0 else "Niveau MAX"
	_upg_btn.disabled = cost < 0

	for c in _slots_box.get_children():
		c.queue_free()
	for i in gm.training_slot_count:
		_slots_box.add_child(_make_slot(i))
	var ucost := gm.training_slot_unlock_cost()
	if ucost >= 0:
		_slots_box.add_child(UIStyle.menu_button("🔒 Débloquer emplacement (%d 💎)" % ucost, UIStyle.COL_GREY, _unlock_slot))

func _make_slot(i: int) -> Control:
	var gm := GameManager
	if i < gm.training_slots.size():
		var mon: MonsterData = gm.training_slots[i]
		return UIStyle.menu_button("%s Nv %d (%d/%d XP) — ❌ Retirer" % [
			mon.mon_name, mon.level, mon.xp, mon.xp_to_next()], UIStyle.COL_RED, func():
			gm.training_remove(mon)
			_refresh())
	return UIStyle.menu_button("➕ Placer un monstre", UIStyle.COL_GREEN, _open_picker)

func _upgrade() -> void:
	_feedback.text = GameManager.upgrade_training()
	_refresh()

func _unlock_slot() -> void:
	_feedback.text = GameManager.unlock_training_slot()
	_refresh()

func _open_picker() -> void:
	var vp := get_viewport_rect().size

	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_picker = layer

	var overlay := ColorRect.new()
	overlay.color = Color("#15171e")
	overlay.position = Vector2.ZERO
	overlay.size = vp
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(overlay)

	var t := Label.new()
	t.text = "Choisis un monstre à entraîner"
	t.add_theme_font_size_override("font_size", 28)
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
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	var any := false
	for mon in GameManager.collection:
		if GameManager.is_busy(mon):    # équipe, mine ou déjà à l'entraînement
			continue
		any = true
		grid.add_child(_train_card(mon))

	if not any:
		var empty := Label.new()
		empty.text = "Aucun monstre disponible."
		empty.add_theme_font_size_override("font_size", 22)
		empty.add_theme_color_override("font_color", Color.WHITE)
		grid.add_child(empty)

	var cancel := UIStyle.menu_button("Annuler", UIStyle.COL_GREY, _close_picker)
	cancel.position = Vector2(vp.x * 0.3, vp.y * 0.86)
	cancel.size = Vector2(vp.x * 0.4, 60)
	overlay.add_child(cancel)

func _train_card(mon: MonsterData) -> Control:
	var vp := get_viewport_rect().size
	var w := (vp.x * 0.84 - 16.0) / 2.0
	var c := UICards.tappable_card(UICards.BORDER_OFF, Vector2(w, 220), func():
		GameManager.training_add(mon)
		_close_picker()
		_refresh())
	var vb: VBoxContainer = c[1]
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 8)
	vb.add_child(UICards.image(mon, 120))
	vb.add_child(UICards.label(mon.mon_name, 26))
	vb.add_child(UICards.label("Nv %d" % mon.level, 20))
	return c[0]

func _close_picker() -> void:
	if _picker != null:
		_picker.queue_free()
		_picker = null
