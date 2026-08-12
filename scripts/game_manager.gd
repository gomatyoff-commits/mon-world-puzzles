extends Node

const MAX_TEAM := 6
const NB_LEVELS := 3
const SAVE_PATH := "user://save.json"

var collection: Array[MonsterData] = []
var team: Array[MonsterData] = []
var enemies: Array[MonsterData] = []
var team_hp: int = 0

var game_mode := "story"
var current_level := 1
var current_wave := 1
var total_waves := 1

# --- MATÉRIAUX (loot) ---
var materials := {}
const MATERIALS := {
	"cristal_feu": "Cristal de Feu",
	"cristal_eau": "Cristal d'Eau",
	"cristal_terre": "Cristal de Terre",
	"cristal_vent": "Cristal de Vent",
	"cristal_lumiere": "Cristal de Lumière",
	"cristal_tenebre": "Cristal de Ténèbre",
}

# --- RECETTES D'ÉVOLUTION (clé = nom du monstre source) ---
var evolutions := {
	"Slime": [
		{ "to": "Slime de Feu",     "element": Elements.E.FIRE,  "min_level": 20, "fodder": 5, "material": "cristal_feu",     "base_hp": 200, "base_atk": 50, "rank": 1, "tex": "res://assets/monster/SlimeDeFeu.png" },
		{ "to": "Slime d'Eau",      "element": Elements.E.WATER, "min_level": 20, "fodder": 5, "material": "cristal_eau",     "base_hp": 200, "base_atk": 50, "rank": 1, "tex": "res://assets/monster/SlimeDEau.png" },
		{ "to": "Slime de Terre",   "element": Elements.E.EARTH, "min_level": 20, "fodder": 5, "material": "cristal_terre",   "base_hp": 200, "base_atk": 50, "rank": 1, "tex": "res://assets/monster/SlimeDeTerre.png" },
		{ "to": "Slime de Vent",    "element": Elements.E.WIND,  "min_level": 20, "fodder": 5, "material": "cristal_vent",    "base_hp": 200, "base_atk": 50, "rank": 1, "tex": "res://assets/monster/SlimeDAir.png" },
		{ "to": "Slime de Lumière", "element": Elements.E.LIGHT, "min_level": 20, "fodder": 5, "material": "cristal_lumiere", "base_hp": 200, "base_atk": 50, "rank": 1, "tex": "res://assets/monster/SlimeDeLumiere.png" },
		{ "to": "Slime de Ténèbre", "element": Elements.E.DARK,  "min_level": 20, "fodder": 5, "material": "cristal_tenebre", "base_hp": 200, "base_atk": 50, "rank": 1, "tex": "res://assets/monster/SlimeDesTenebres.png" },
	],
}

func _ready() -> void:
	_build_collection()
	_load()
	if team.is_empty():
		team = collection.slice(0, MAX_TEAM)
	team_hp = team_max_hp()

func _build_collection() -> void:
	collection = [
		MonsterData.new("Slime", Elements.E.NEUTRAL, 100, 10, 1, "res://assets/monster/Slime.png", 1, 0),
		MonsterData.new("Slime", Elements.E.NEUTRAL, 100, 10, 1, "res://assets/monster/Slime.png", 1, 0),
		MonsterData.new("Slime", Elements.E.NEUTRAL, 100, 10, 1, "res://assets/monster/Slime.png", 1, 0),
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
			MonsterData.new("Slime d'Eau", Elements.E.WATER, 800, 130, 3, "res://assets/monster/SlimeDEau.png"),
			MonsterData.new("Slime de Terre", Elements.E.EARTH, 900, 120, 4, "res://assets/monster/SlimeDeTerre.png"),
		]
		3: return [
			MonsterData.new("Slime de Vent", Elements.E.WIND, 900, 150, 3, "res://assets/monster/SlimeDAir.png"),
			MonsterData.new("Slime de Lumière", Elements.E.LIGHT, 1000, 160, 3, "res://assets/monster/SlimeDeLumiere.png"),
			MonsterData.new("Slime de Ténèbre", Elements.E.DARK, 1300, 200, 4, "res://assets/monster/SlimeDesTenebres.png"),
		]
		_: return [ MonsterData.new("Boss", Elements.E.DARK, 2000, 250, 3, "res://assets/monster/SlimeDesTenebres.png") ]

# --- MODE EVENT (3 vagues de slimes) ---
func start_event() -> void:
	game_mode = "event"
	total_waves = 3
	current_wave = 1
	team_hp = team_max_hp()
	enemies = _build_event_wave(1)

func _build_event_wave(wave: int) -> Array[MonsterData]:
	var list: Array[MonsterData] = []
	for i in wave:
		list.append(MonsterData.new("Slime", Elements.E.NEUTRAL, 100, 10, 2, "res://assets/monster/Slime.png"))
	return list

func next_wave() -> bool:
	if current_wave >= total_waves:
		return false
	current_wave += 1
	if game_mode == "event":
		enemies = _build_event_wave(current_wave)
	else:
		enemies = _build_level_enemies(current_level)
	return true

# --- LOOT ---
func add_material(id: String, count := 1) -> void:
	materials[id] = int(materials.get(id, 0)) + count

# 1 chance sur 4 d'obtenir un Slime (générique -> évoluable)
func try_drop_slime() -> MonsterData:
	if randi() % 4 == 0:
		# On ne drop QUE des slimes de RANG 0 (les rang 1 s'obtiennent par évolution)
		var slime := MonsterData.new("Slime", Elements.E.NEUTRAL, 100, 10, 1, "res://assets/monster/Slime.png", 1, 0)
		collection.append(slime)
		return slime
	return null

# Butin de fin d'event : chaque slime affronté a 1 chance sur 2 de lâcher un cristal aléatoire
func event_loot() -> String:
	# nombre de slimes affrontés = 1 + 2 + ... + total_waves
	var nb_slimes := 0
	for w in range(1, total_waves + 1):
		nb_slimes += w

	var crystal_counts := {}
	for i in nb_slimes:
		if randi() % 2 == 0:                                 # 1 chance sur 2
			var crys: String = MATERIALS.keys()[randi() % MATERIALS.size()]   # cristal aléatoire
			add_material(crys, 1)
			crystal_counts[crys] = int(crystal_counts.get(crys, 0)) + 1

	var parts: Array[String] = []
	for id in crystal_counts.keys():
		parts.append("%dx %s" % [crystal_counts[id], MATERIALS[id]])

	# 1 chance sur 4 d'obtenir aussi un Slime
	var slime := try_drop_slime()
	if slime != null:
		parts.append(slime.mon_name)

	save_game()
	return "🎁 " + " + ".join(parts) if parts.size() > 0 else "Aucun butin cette fois..."

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

# --- ÉVOLUTION ---
# Liste TOUTES les évolutions possibles d'un monstre
func get_evolutions(mon: MonsterData) -> Array:
	return evolutions.get(mon.mon_name, [])

func can_evolve(mon: MonsterData, rec: Dictionary, fodder: Array) -> String:
	if rec.is_empty():
		return "Choisis une évolution."
	if mon.level < int(rec["min_level"]):
		return "Niveau %d minimum requis." % rec["min_level"]
	if fodder.size() != int(rec["fodder"]):
		return "%d monstres à sacrifier requis." % rec["fodder"]
	if int(materials.get(rec["material"], 0)) < 1:
		return "Manque : " + MATERIALS[rec["material"]]
	return ""

func evolve(mon: MonsterData, rec: Dictionary, fodder: Array) -> bool:
	if can_evolve(mon, rec, fodder) != "":
		return false
	for f in fodder:
		if f == mon: continue
		team.erase(f)
		collection.erase(f)
	materials[rec["material"]] = int(materials[rec["material"]]) - 1
	mon.mon_name = rec["to"]
	mon.element = int(rec["element"])
	mon.base_hp = int(rec["base_hp"])
	mon.base_atk = int(rec["base_atk"])
	mon.rank = int(rec.get("rank", mon.rank + 1))
	mon.texture_path = rec["tex"]
	mon.texture = load(rec["tex"]) if rec["tex"] != "" else load("res://icon.svg")
	mon.hp = mon.max_hp
	team_hp = team_max_hp()
	save_game()
	return true

# --- SAUVEGARDE ---
func save_game() -> void:
	var data := { "collection": [], "team": [], "materials": materials }
	for m in collection:
		data["collection"].append({
			"name": m.mon_name, "element": m.element,
			"base_hp": m.base_hp, "base_atk": m.base_atk,
			"level": m.level, "xp": m.xp, "tex": m.texture_path,
			"rank": m.rank,
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
	materials = data.get("materials", {})
	var col = data.get("collection", [])
	if col.size() > 0:
		collection.clear()
		for c in col:
			var m := MonsterData.new(c["name"], int(c["element"]),
				int(c["base_hp"]), int(c["base_atk"]), 1, c.get("tex", ""),
				int(c["level"]), int(c.get("rank", 0)))
			m.xp = int(c["xp"])
			m.hp = m.max_hp
			collection.append(m)
	team.clear()
	for idx in data.get("team", []):
		var i := int(idx)
		if i >= 0 and i < collection.size():
			team.append(collection[i])
