extends Node

const MAX_TEAM := 6
const NB_LEVELS := 3
const SAVE_PATH := "user://save.json"

var collection: Array[MonsterData] = []
var team: Array[MonsterData] = []
var enemies: Array[MonsterData] = []
var team_hp: int = 0

var game_mode := "story"          # "story" ou "event"
var current_level := 1
var current_wave := 1
var total_waves := 1

func _ready() -> void:
	_build_collection()
	_load()
	if team.is_empty():
		team = collection.slice(0, MAX_TEAM)
	team_hp = team_max_hp()

func _build_collection() -> void:
	collection = [
		MonsterData.new("Slime", Elements.E.NEUTRAL, 100, 10, 1, "res://assets/monster/Slime.png"),
		MonsterData.new("Slime de Feu",     Elements.E.FIRE,  200, 50, 1, "res://assets/monster/SlimeDeFeu.png"),
		MonsterData.new("Slime d'Eau",      Elements.E.WATER, 200, 50),
		MonsterData.new("Slime de Terre",   Elements.E.EARTH, 220, 45),
		MonsterData.new("Slime de Vent",    Elements.E.WIND,  180, 55),
		MonsterData.new("Slime de Lumière", Elements.E.LIGHT, 200, 50),
		MonsterData.new("Slime de Ténèbre", Elements.E.DARK,  200, 50),
	]

# --- MODE HISTOIRE ---
func start_level(level: int) -> void:
	game_mode = "story"
	current_level = level
	total_waves = 1
	current_wave = 1
	team_hp = team_max_hp()
	enemies = _build_level_enemies(level)

func _build_level_enemies(level: int) -> Array[MonsterData]:
	match level:
		1: return [ MonsterData.new("Slime de Feu", Elements.E.FIRE, 600, 100, 3, "res://assets/monster/SlimeDeFeu.png") ]
		2: return [
			MonsterData.new("Slime d'Eau", Elements.E.WATER, 800, 130, 3, ),
			MonsterData.new("Slime de Terre", Elements.E.EARTH, 900, 120, 4, ),
		]
		3: return [
			MonsterData.new("Slime de Vent", Elements.E.WIND, 900, 150, 3, ),
			MonsterData.new("Slime de lumière", Elements.E.LIGHT, 1000, 160, 3, ),
			MonsterData.new("Slime de ténèbre", Elements.E.NEUTRAL, 1300, 200, 4, ),
		]
		_: return [ MonsterData.new("Boss", Elements.E.DARK, 2000, 250, 3) ]

# --- MODE EVENT (3 vagues de slimes) ---
func start_event() -> void:
	game_mode = "event"
	total_waves = 3
	current_wave = 1
	team_hp = team_max_hp()
	enemies = _build_event_wave(1)

func _build_event_wave(wave: int) -> Array[MonsterData]:
	var list: Array[MonsterData] = []
	for i in wave:                      # vague 1 -> 1 slime, vague 3 -> 3 slimes
		var el: int = Elements.ORB_ELEMENTS[randi() % Elements.ORB_ELEMENTS.size()]
		list.append(MonsterData.new("Slime", el, 100, 10, 2, "res://assets/monster/Slime.png"))
	return list

# Passe à la vague suivante. Retourne false s'il n'y en a plus.
func next_wave() -> bool:
	if current_wave >= total_waves:
		return false
	current_wave += 1
	if game_mode == "event":
		enemies = _build_event_wave(current_wave)
	else:
		enemies = _build_level_enemies(current_level)
	return true

# 1 chance sur 4 d'obtenir un slime (loot event)
func try_drop_slime() -> MonsterData:
	if randi() % 4 == 0:
		var el: int = Elements.ORB_ELEMENTS[randi() % Elements.ORB_ELEMENTS.size()]
		var slime := MonsterData.new("Slime " + Elements.NAMES[el], el, 100, 10)
		collection.append(slime)
		save_game()
		return slime
	return null

# --- PV équipe ---
func team_max_hp() -> int:
	var t := 0
	for m in team: t += m.max_hp
	return t

func team_total_hp() -> int:
	return team_hp

func gain_team_xp(amount: int) -> void:
	for m in team: m.add_xp(amount)
	save_game()

# --- FUSION (alchimie) ---
func fuse(base: MonsterData, fodder: Array) -> int:
	var gained := 0
	for f in fodder:
		if f == base: continue
		gained += f.fusion_value()
		team.erase(f)
		collection.erase(f)
	base.add_xp(gained)
	team_hp = team_max_hp()
	save_game()
	return gained

# --- SAUVEGARDE ---
func save_game() -> void:
	var data := { "collection": [], "team": [] }
	for m in collection:
		data["collection"].append({
			"name": m.mon_name, "element": m.element,
			"base_hp": m.base_hp, "base_atk": m.base_atk,
			"level": m.level, "xp": m.xp, "tex": m.texture_path,
		})
	for m in team:
		data["team"].append(collection.find(m))
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data == null: return
	var col = data.get("collection", [])
	if col.size() > 0:
		collection.clear()
		for c in col:
			var m := MonsterData.new(c["name"], int(c["element"]),
				int(c["base_hp"]), int(c["base_atk"]), 1, c.get("tex", ""), int(c["level"]))
			m.xp = int(c["xp"])
			m.hp = m.max_hp
			collection.append(m)
	team.clear()
	for idx in data.get("team", []):
		var i := int(idx)
		if i >= 0 and i < collection.size():
			team.append(collection[i])
