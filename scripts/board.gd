# board.gd
extends Node2D
@onready var ui: CanvasLayer = get_node("../UI")   # chemin depuis Board vers UI

const COLS := 6
const ROWS := 5
const CELL := 160          # taille d'une case en pixels
const ORB_SCENE := preload("res://scenes/Orb.tscn")
const MAX_MOVE_TIME := 4.5 # secondes autorisées pour déplacer
const BG_PAD := 14        # marge du grand bloc autour du board
const CELL_INSET := 6     # espace entre le bord d'une case et son petit bloc
const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const DEBUG := false

var grid: Array[Array] = []       # grid[x][y] -> Orb
var held_orb: Orb = null
var last_cell := Vector2i(-1, -1)
var is_moving := false
var move_timer := 0.0
var is_resolving := false
var battle_over := false

func _ready() -> void:
	_build_grid()
	_center_board_bottom()
	queue_redraw()

func _draw() -> void:
	var board_w := COLS * CELL
	var board_h := ROWS * CELL
	
	# --- GRAND BLOC (contour de tout le board) ---
	var big := StyleBoxFlat.new()
	big.bg_color = Color(0, 0, 0, 0.35)          # fond sombre translucide
	big.set_corner_radius_all(22)                # coins arrondis
	big.set_border_width_all(3)
	big.border_color = Color(1, 1, 1, 0.15)      # léger liseré clair
	draw_style_box(big, Rect2(
		-BG_PAD, -BG_PAD,
		board_w + BG_PAD * 2, board_h + BG_PAD * 2
	))
	
	# --- PETITS BLOCS (une case par orbe) ---
	var cell_box := StyleBoxFlat.new()
	cell_box.bg_color = Color(1, 1, 1, 0.06)     # léger creux clair
	cell_box.set_corner_radius_all(14)
	for x in COLS:
		for y in ROWS:
			draw_style_box(cell_box, Rect2(
				x * CELL + CELL_INSET,
				y * CELL + CELL_INSET,
				CELL - CELL_INSET * 2,
				CELL - CELL_INSET * 2
			))

func _center_board_bottom() -> void:
	var vp := get_viewport_rect().size
	var board_w := COLS * CELL
	var board_h := ROWS * CELL
	position.x = (vp.x - board_w) / 2.0        # centré horizontalement
	position.y = vp.y - board_h - 20           # collé en bas (marge 20px)

# --- Construction de la grille ---
func _build_grid() -> void:
	_clear_grid()
	for x in COLS:
		grid.append([])
		for y in ROWS:
			var orb := _spawn_orb(_random_orb_element(), Vector2i(x, y))
			grid[x].append(orb)

func _spawn_orb(elem: int, gpos: Vector2i) -> Orb:
	var orb := ORB_SCENE.instantiate() as Orb
	orb.setup(elem, gpos)
	orb.position = grid_to_pixel(gpos)
	add_child(orb)
	return orb

# Tire une couleur PARMI LES 6 ORBES (jamais NEUTRAL, qui n'a pas d'orbe)
func _random_orb_element() -> int:
	return Elements.ORB_ELEMENTS[randi() % Elements.ORB_ELEMENTS.size()]

# --- Conversions grille <-> pixels ---
func grid_to_pixel(p: Vector2i) -> Vector2:
	return Vector2(p.x * CELL + CELL / 2.0, p.y * CELL + CELL / 2.0)

func pixel_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(int(pos.x / CELL), int(pos.y / CELL))

func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < COLS and p.y >= 0 and p.y < ROWS

func _clear_grid() -> void:
	for child in get_children():
		if child is Orb:
			child.queue_free()
	grid.clear()

func _input(event: InputEvent) -> void:
	# --- Tactile (mobile / émulation) ---
	if event is InputEventScreenTouch:
		if event.pressed:
			_grab(event.position)
		else:
			_release()
	elif event is InputEventScreenDrag and is_moving:
		_drag(event.position)
	
	# --- Souris (test sur PC) ---
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_grab(event.position)
		else:
			_release()
	elif event is InputEventMouseMotion and is_moving:
		_drag(event.position)

func _grab(screen_pos: Vector2) -> void:
	if not _can_play():
		return
	var cell := pixel_to_grid(to_local(screen_pos))
	if not in_bounds(cell):
		return
	held_orb = grid[cell.x][cell.y]
	last_cell = cell
	is_moving = true
	move_timer = MAX_MOVE_TIME
	held_orb.z_index = 10

func _drag(screen_pos: Vector2) -> void:
	if held_orb == null:
		return
	var local := to_local(screen_pos)
	held_orb.position = local
	var cell := pixel_to_grid(local)
	if in_bounds(cell) and cell != last_cell:
		_swap_orbs(last_cell, cell)
		last_cell = cell

func _swap_orbs(from: Vector2i, to: Vector2i) -> void:
	var moving: Orb = grid[from.x][from.y]
	var other: Orb = grid[to.x][to.y]
	grid[from.x][from.y] = other
	grid[to.x][to.y] = moving
	other.grid_pos = from
	moving.grid_pos = to
	other.move_to(grid_to_pixel(from))

func _release() -> void:
	if not is_moving:
		return
	is_moving = false
	if held_orb:
		held_orb.z_index = 0
		held_orb.move_to(grid_to_pixel(held_orb.grid_pos))
		held_orb = null
	resolve_matches()

func _process(delta: float) -> void:
	if is_moving:
		move_timer -= delta
		if move_timer <= 0.0:
			_release()

# Renvoie un tableau de GROUPES.
# Chaque groupe est un Array[Vector2i] d'orbes reliés de même couleur = 1 combo.
func find_match_groups() -> Array:
	# --- Étape 1 : repérer toutes les cases matchées (3+) ---
	var matched := {}   # Vector2i -> true

	# Horizontal
	for y in ROWS:
		var run: Array[Vector2i] = [Vector2i(0, y)]
		for x in range(1, COLS):
			if _same_element(Vector2i(x, y), Vector2i(x - 1, y)):
				run.append(Vector2i(x, y))
			else:
				_commit_run(run, matched)
				run = [Vector2i(x, y)]
		_commit_run(run, matched)

	# Vertical
	for x in COLS:
		var run: Array[Vector2i] = [Vector2i(x, 0)]
		for y in range(1, ROWS):
			if _same_element(Vector2i(x, y), Vector2i(x, y - 1)):
				run.append(Vector2i(x, y))
			else:
				_commit_run(run, matched)
				run = [Vector2i(x, y)]
		_commit_run(run, matched)

	# --- Étape 2 : regrouper par composantes connexes de même couleur ---
	var groups: Array = []
	var visited := {}

	for cell in matched.keys():
		if visited.has(cell):
			continue
		# flood fill à partir de cette case
		var group: Array[Vector2i] = []
		var elem: int = grid[cell.x][cell.y].element
		var stack: Array[Vector2i] = [cell]
		visited[cell] = true

		while stack.size() > 0:
			var c: Vector2i = stack.pop_back()
			group.append(c)
			# 4 voisins orthogonaux
			for dir in DIRS:
				var n: Vector2i = c + dir
				if matched.has(n) and not visited.has(n):
					if grid[n.x][n.y] != null and grid[n.x][n.y].element == elem:
						visited[n] = true
						stack.append(n)

		groups.append(group)

	return groups

func _commit_run(run: Array[Vector2i], matched: Dictionary) -> void:
	if run.size() >= 3:
		for p in run:
			matched[p] = true

func _same_element(a: Vector2i, b: Vector2i) -> bool:
	var oa: Orb = grid[a.x][a.y]
	var ob: Orb = grid[b.x][b.y]
	if oa == null or ob == null:
		return false
	return oa.element == ob.element

func _clear_matches(matches: Array[Vector2i]) -> void:
	var tweens: Array = []
	for cell in matches:
		var orb: Orb = grid[cell.x][cell.y]
		if orb == null:
			continue
		grid[cell.x][cell.y] = null      # la case devient vide
		var tw = create_tween()
		tw.tween_property(orb, "scale", Vector2.ZERO, 0.12)\
		  .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback(orb.queue_free) # supprime l'orbe à la fin
		tweens.append(tw)
	
	 # On attend la fin de l'animation de disparition
	if tweens.size() > 0:
		await tweens[0].finished

func _apply_gravity() -> void:
	var tweens: Array = []
	
	for x in COLS:
		var write_y := ROWS -1       # prochaine case libre en partant du bas
		
		# On parcourt la colonne de bas en haut
		for y in range(ROWS - 1, -1, -1):
			var orb: Orb = grid[x][y]
			if orb != null:
				if write_y != y:
					# déplace l'orbe vers le bas
					grid[x][write_y] = orb
					grid[x][y] = null
					orb.grid_pos =  Vector2i(x, write_y)
					var tw := create_tween()
					tw.tween_property(orb, "position",
						grid_to_pixel(Vector2i(x, write_y)), 0.15)\
						.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
					tweens.append(tw)
				write_y -= 1
	if tweens.size() > 0:
		await tweens[0].finished

func _refill() -> void:
	var tweens: Array = []
	
	for x in COLS:
		for y in ROWS:
			if grid[x][y] == null:
				var orb := _spawn_orb(_random_orb_element(), Vector2i(x, y))
				# On le place au-dessus de l'écran puis il tombe à sa place
				var start_pos := grid_to_pixel(Vector2i(x, y))
				orb.position = start_pos - Vector2(0, CELL * ROWS)
				grid[x][y] = orb
				var tw := create_tween()
				tw.tween_property(orb, "position", start_pos, 0.18)\
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				tweens.append(tw)
		
	if tweens.size() > 0:
		await tweens[0].finished

func resolve_matches() -> void:
	if is_resolving:
		return
	is_resolving = true

	var combo_count := 0
	var dmg_single := {}     # dégâts sur 1 seul ennemi
	var dmg_all := {}        # dégâts de ZONE (groupes de 5+) -> tous les ennemis

	while true:
		var groups := find_match_groups()
		if groups.is_empty():
			break

		for group in groups:
			combo_count += 1
			var elem: int = grid[group[0].x][group[0].y].element
			var nb: int = group.size()
			if DEBUG:
				print("Combo n°", combo_count, " : ", nb, " orbes ", Elements.NAMES[elem])

			# 5 orbes ou plus détruits ensemble -> attaque de ZONE
			var bucket: Dictionary = dmg_all if nb >= 5 else dmg_single

			for m in GameManager.team:
				if GameManager.team_hp <= 0:
					continue
				var raw: float = (1.0 + (nb - 3) * 0.25) * m.atk
				if m.element == elem:
					bucket[elem] = bucket.get(elem, 0.0) + raw
				elif m.element == Elements.E.NEUTRAL:
					bucket[Elements.E.NEUTRAL] = bucket.get(Elements.E.NEUTRAL, 0.0) + raw

		var all_cells: Array[Vector2i] = []
		for group in groups:
			for c in group:
				all_cells.append(c)

		await _clear_matches(all_cells)
		await _apply_gravity()
		await _refill()

	# --- Multiplicateur de COMBO global : 4=x1.1, 5=x1.2, 6=x1.3 ... ---
	var combo_mult := 1.0
	if combo_count >= 4:
		combo_mult = 1.0 + (combo_count - 3) * 0.1

	_apply_damage_single(dmg_single, combo_mult)   # 1 ennemi
	_apply_damage_all(dmg_all, combo_mult)         # tous les ennemis (zone)

	ui.show_combo(combo_count)
	ui.refresh_all()
	_end_player_turn()
	is_resolving = false

# Dégâts sur le premier ennemi vivant
func _apply_damage_single(dmg: Dictionary, combo_mult: float) -> void:
	var target: MonsterData = _first_alive_enemy()
	if target == null:
		return
	_deal(target, dmg, combo_mult)

# Dégâts de ZONE : touche TOUS les ennemis vivants
func _apply_damage_all(dmg: Dictionary, combo_mult: float) -> void:
	if dmg.is_empty():
		return
	for e in GameManager.enemies:
		if e.is_alive():
			_deal(e, dmg, combo_mult)

# Applique les dégâts à une cible (table élémentaire + combo + défense, min 1)
func _deal(target: MonsterData, dmg: Dictionary, combo_mult: float) -> void:
	var total := 0.0
	for elem in dmg.keys():
		total += dmg[elem] * Elements.get_multiplier(elem, target.element)
	total *= combo_mult
	var dealt := int(total) - target.defense
	if dealt < 1:
		dealt = 1
	target.hp = max(0, target.hp - dealt)
	if DEBUG:
		print(target.mon_name, " prend ", dealt, " dégâts (PV: ", target.hp, ")")

func _first_alive_enemy() -> MonsterData:
	for e in GameManager.enemies:
		if e.is_alive():
			return e
	return null

func _end_player_turn() -> void:
	# victoire ?
	if _first_alive_enemy() == null:
		# reste-t-il des vagues ?
		if GameManager.next_wave():
			ui.rebuild_enemies()
			ui.refresh_all()
			return                      # le combat continue (vague suivante)

		# combat terminé
		var extra := ""
		if GameManager.game_mode == "event":
			GameManager.gain_team_xp(100)
			extra = GameManager.event_loot()
		else:
			var reward := GameManager.current_level * 200
			GameManager.gain_team_xp(reward)
			extra = "+%d XP" % reward

		ui.refresh_all()
		ui.show_result(true, extra)
		battle_over = true
		return
	
	# tour des ennemis
	for e in GameManager.enemies:
		if not e.is_alive():
			continue
		e.turn_counter -= 1
		if e.turn_counter <= 0:
			_enemy_attack(e)
			e.turn_counter = 2   # reset du compteur (à ajuster par ennemi)
	
	ui.refresh_all()
	# défaite ?
	if GameManager.team_total_hp() <= 0:
		ui.show_result(false)
		battle_over = true

func _enemy_attack(e: MonsterData) -> void:
	var dmg := e.atk - GameManager.team_defense()
	if dmg < 1:
		dmg = 1
	GameManager.team_hp = max(0, GameManager.team_hp - e.atk)
	if DEBUG:
		print(e.mon_name, " attaque l'équipe : -", e.atk, " PV (reste ", GameManager.team_hp, ")")

func _can_play() -> bool:
	return not is_resolving and not battle_over
