extends Node

const MAX_TEAM := 6
const SAVE_PATH := "user://save.json"

# --- NIVEAUX : juste des IDs + niveau + tours. Créer un niveau = 1 ligne ! ---
const LEVELS := {
	1: [ {"id": "slime_feu", "lv": 6, "turns": 3} ],
	2: [ {"id": "slime_eau", "lv": 8, "turns": 3}, {"id": "slime_terre", "lv": 8, "turns": 4} ],
	3: [ {"id": "slime_vent", "lv": 10, "turns": 3}, {"id": "slime_lumiere", "lv": 10, "turns": 3}, {"id": "slime_tenebre", "lv": 12, "turns": 4} ],
}
var NB_LEVELS := LEVELS.size()

# --- ÉVOLUTIONS : par species_id, cible = un autre id de la bibliothèque ---
var evolutions := {
	"slime": [
		{ "to_id": "slime_feu",     "min_level": 10, "fodder": 5, "material": "cristal_feu" },
		{ "to_id": "slime_eau",     "min_level": 10, "fodder": 5, "material": "cristal_eau" },
		{ "to_id": "slime_terre",   "min_level": 10, "fodder": 5, "material": "cristal_terre" },
		{ "to_id": "slime_vent",    "min_level": 10, "fodder": 5, "material": "cristal_vent" },
		{ "to_id": "slime_lumiere", "min_level": 10, "fodder": 5, "material": "cristal_lumiere" },
		{ "to_id": "slime_tenebre", "min_level": 10, "fodder": 5, "material": "cristal_tenebre" },
	],
}

var collection: Array[MonsterData] = []
var team: Array[MonsterData] = []
var enemies: Array[MonsterData] = []
var team_hp: int = 0
var materials := {}

var game_mode := "story"
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
	collection = [ MonsterDB.create("slime"), MonsterDB.create("slime"), MonsterDB.create("slime") ]

# --- MODE HISTOIRE ---
func start_level(level: int) -> void:
	game_mode = "story"
	current_level = level
	total_waves = 1
	current_wave = 1
	team_hp = team_max_hp()
	enemies = _build_level_enemies(level)

func _build_level_enemies(level: int) -> Array[MonsterData]:
	var list: Array[MonsterData] = []
	for e in LEVELS.get(level, []):
		list.append(MonsterDB.create(e["id"], int(e.get("lv", 1)), int(e.get("turns", 1))))
	return list

# --- MODE EVENT ---
func start_event() -> void:
	game_mode = "event"
	total_waves = 3
	current_wave = 1
	team_hp = team_max_hp()
	enemies = _build_event_wave(1)

func _build_event_wave(wave: int) -> Array[MonsterData]:
	var list: Array[MonsterData] = []
	for i in wave:
		list.append(MonsterDB.create("slime", 1, 2))
	return list

func next_wave() -> bool:
	if current_wave >= total_waves:
		return false
	current_wave += 1
	enemies = _build_event_wave(current_wave) if game_mode == "event" else _build_level_enemies(current_level)
	return true

# --- LOOT (via LootDB) ---
func add_material(id: String, count := 1) -> void:
	materials[id] = int(materials.get(id, 0)) + count

func event_loot() -> String:
	var nb_slimes := 0
	for w in range(1, total_waves + 1):
		nb_slimes += w
	var result: Dictionary = LootDB.roll("event_slime", nb_slimes)

	var parts: Array[String] = []
	for id in result["materials"].keys():
		add_material(id, int(result["materials"][id]))
		parts.append("%dx %s" % [result["materials"][id], LootDB.MATERIALS[id]])
	for mon_id in result["monsters"]:
		collection.append(MonsterDB.create(mon_id))   # rang 0 garanti (défini dans la lib)
		parts.append(MonsterDB.display_name(mon_id))

	save_game()
	return "🎁 " + " + ".join(parts) if parts.size() > 0 else "Aucun butin cette fois..."

# --- PV équipe ---
func team_max_hp() -> int:
	var t := 0
	for m in team: t += m.max_hp
	return t

func team_total_hp() -> int:
	return team_hp

func team_defense() -> int:
	if team.is_empty():
		return 0
	var total := 0
	for m in team:
		total += m.defense
	return int(total / team.size())

func gain_team_xp(amount: int) -> void:
	for m in team: m.add_xp(amount)
	save_game()

# --- FUSION ---
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
func get_evolutions(mon: MonsterData) -> Array:
	return evolutions.get(mon.species_id, [])

func evo_name(rec: Dictionary) -> String:
	return MonsterDB.display_name(rec["to_id"])

func can_evolve(mon: MonsterData, rec: Dictionary, fodder: Array) -> String:
	if rec.is_empty():
		return "Choisis une évolution."
	if mon.level < int(rec["min_level"]):
		return "Niveau %d minimum requis." % rec["min_level"]
	if fodder.size() != int(rec["fodder"]):
		return "%d monstres à sacrifier requis." % rec["fodder"]
	if int(materials.get(rec["material"], 0)) < 1:
		return "Manque : " + LootDB.MATERIALS[rec["material"]]
	return ""

func evolve(mon: MonsterData, rec: Dictionary, fodder: Array) -> bool:
	if can_evolve(mon, rec, fodder) != "":
		return false
	for f in fodder:
		if f == mon: continue
		team.erase(f)
		collection.erase(f)
	materials[rec["material"]] = int(materials[rec["material"]]) - 1
	# on transforme via la bibliothèque
	var s = MonsterDB.species[rec["to_id"]]
	mon.species_id = rec["to_id"]
	mon.mon_name = s["name"]
	mon.element = int(s["el"])
	mon.base_hp = int(s["hp"])
	mon.base_atk = int(s["atk"])
	mon.rank = int(s["rank"])
	mon.texture_path = s["tex"]
	mon.texture = load(s["tex"])
	mon.level = 1
	mon.xp = 0
	mon.hp = mon.max_hp
	team_hp = team_max_hp()
	save_game()
	return true

# --- SAUVEGARDE (simplifiée : on ne stocke que id + level + xp) ---
func save_game() -> void:
	var data := { "collection": [], "team": [], "materials": materials }
	for m in collection:
		data["collection"].append({ "id": m.species_id, "level": m.level, "xp": m.xp })
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
			if not MonsterDB.has(c["id"]): continue
			var m := MonsterDB.create(c["id"], int(c["level"]))
			m.xp = int(c["xp"])
			m.hp = m.max_hp
			collection.append(m)
	team.clear()
	for idx in data.get("team", []):
		var i := int(idx)
		if i >= 0 and i < collection.size():
			team.append(collection[i])
