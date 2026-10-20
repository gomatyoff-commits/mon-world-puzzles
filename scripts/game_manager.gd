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
		{ "to_id": "slime_feu",     "min_level": 10, "fodder": 1, "material": "cristal_feu" },
		{ "to_id": "slime_eau",     "min_level": 10, "fodder": 1, "material": "cristal_eau" },
		{ "to_id": "slime_terre",   "min_level": 10, "fodder": 1, "material": "cristal_terre" },
		{ "to_id": "slime_vent",    "min_level": 10, "fodder": 1, "material": "cristal_vent" },
		{ "to_id": "slime_lumiere", "min_level": 10, "fodder": 1, "material": "cristal_lumiere" },
		{ "to_id": "slime_tenebre", "min_level": 10, "fodder": 1, "material": "cristal_tenebre" },
	],
}

var collection: Array[MonsterData] = []
var team: Array[MonsterData] = []
var enemies: Array[MonsterData] = []
var team_hp: int = 0
var materials := {}
var player_name := "Joueur"   # pseudo du joueur
var coins := 500   # pièces (solde de départ)
var gems := 100    # gemmes (solde de départ)
var discovered := {}   # species_id -> true (monstres déjà possédés ou vus)

# --- MINE À GEMMES ---
const GEM_COST := 1000.0            # points nécessaires pour 1 gemme
const MINE_SLOT_COSTS := [50, 150, 400]   # coût (gemmes) pour débloquer emplacements 2, 3, 4
var mine_slots: Array[MonsterData] = []
var mine_capacity := 10             # stockage max de gemmes
var mine_stored := 0                # gemmes minées en attente de collecte
var mine_progress := 0.0            # points vers la prochaine gemme
var mine_last_ts := 0               # horodatage (temps réel) de la dernière MAJ
var mine_slot_count := 1            # nombre d'emplacements débloqués
var mine_level := 1                 # niveau de stockage

var game_mode := "story"
var current_level := 1
var current_wave := 1
var total_waves := 1

func _ready() -> void:
	_build_collection()
	_load()
	for m in collection:
		discover(m.species_id)
	if team.is_empty():
		team = collection.slice(0, MAX_TEAM)
	team_hp = team_max_hp()
	update_mine()

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
		discover(e["id"])
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
		discover("slime")
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

# Pièces lâchées par un monstre vaincu
func coin_drop(mon: MonsterData) -> int:
	return (500 * (mon.rank + 1)) + (mon.level * (mon.rank + 1))

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
		discover(mon_id)

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
	var cost := fusion_cost(base, fodder)
	if coins < cost:
		return -1
	coins -= cost
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

func fusion_cost(base: MonsterData, fodder: Array) -> int:
	return 100 * (base.rank + 1) * max(1, fodder.size())

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
	if coins < evolution_cost(mon):
		return "Manque %d 🪙." % evolution_cost(mon)
	return ""

func evolve(mon: MonsterData, rec: Dictionary, fodder: Array) -> bool:
	if can_evolve(mon, rec, fodder) != "":
		return false
	coins -= evolution_cost(mon)
	discover(rec["to_id"])
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

func evolution_cost(mon: MonsterData) -> int:
	return 1000 * (mon.rank + 1)

# --- SAUVEGARDE (simplifiée : on ne stocke que id + level + xp) ---
func save_game() -> void:
	var data := {
		"collection": [], "team": [], "materials": materials,
		"coins": coins, "gems": gems, "player_name": player_name,
		"mine_slots": [], "mine_capacity": mine_capacity, "mine_stored": mine_stored,
		"mine_progress": mine_progress, "mine_last_ts": mine_last_ts,
		"mine_slot_count": mine_slot_count, "mine_level": mine_level,
		"discovered": discovered
	}
	for m in collection:
		data["collection"].append({ "id": m.species_id, "level": m.level, "xp": m.xp })
	for m in team:
		data["team"].append(collection.find(m))
	for m in mine_slots:
		data["mine_slots"].append(collection.find(m))
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
	player_name = str(data.get("player_name", player_name))
	coins = int(data.get("coins", coins))
	gems = int(data.get("gems", gems))
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
	
	mine_capacity   = int(data.get("mine_capacity", mine_capacity))
	mine_stored     = int(data.get("mine_stored", mine_stored))
	mine_progress   = float(data.get("mine_progress", mine_progress))
	mine_last_ts    = int(data.get("mine_last_ts", mine_last_ts))
	mine_slot_count = int(data.get("mine_slot_count", mine_slot_count))
	mine_level      = int(data.get("mine_level", mine_level))
	discovered      = data.get("discovered", {})
	mine_slots.clear()
	for idx in data.get("mine_slots", []):
		var mi := int(idx)
		if mi >= 0 and mi < collection.size():
			mine_slots.append(collection[mi])

# --- BOUTIQUE ---
func buy_monster(species_id: String, gem_cost: int) -> String:
	if not MonsterDB.has(species_id):
		return "Monstre inconnu."
	if gems < gem_cost:
		return "❌ Pas assez de gemmes !"
	gems -= gem_cost
	discover(species_id)
	collection.append(MonsterDB.create(species_id))
	save_game()
	return "✅ %s ajouté à ta collection !" % MonsterDB.display_name(species_id)

func mine_rate() -> int:
	var r := 0
	for m in mine_slots:
		r += m.work
	return r

func update_mine() -> void:
	var now := int(Time.get_unix_time_from_system())
	if mine_last_ts == 0:
		mine_last_ts = now
		return
	var elapsed_min := float(now - mine_last_ts) / 60.0
	mine_last_ts = now
	if elapsed_min <= 0.0 or mine_slots.is_empty():
		return
	mine_progress += float(mine_rate()) * elapsed_min
	while mine_progress >= GEM_COST and mine_stored < mine_capacity:
		mine_progress -= GEM_COST
		mine_stored += 1
	if mine_stored >= mine_capacity:
		mine_progress = 0.0   # mine pleine : va collecter !

func collect_mine() -> int:
	update_mine()
	var got := mine_stored
	gems += got
	mine_stored = 0
	save_game()
	return got

func mine_add(mon: MonsterData) -> bool:
	update_mine()
	if mine_slots.size() >= mine_slot_count or mine_slots.has(mon):
		return false
	if team.has(mon):
		return false   # un monstre de l'équipe ne peut pas miner
	mine_slots.append(mon)
	save_game()
	return true

func mine_remove(mon: MonsterData) -> void:
	update_mine()
	mine_slots.erase(mon)
	save_game()

func mine_slot_unlock_cost() -> int:
	var idx := mine_slot_count - 1
	if idx >= MINE_SLOT_COSTS.size():
		return -1   # maximum atteint
	return MINE_SLOT_COSTS[idx]

func unlock_mine_slot() -> String:
	var cost := mine_slot_unlock_cost()
	if cost < 0:
		return "Nombre d'emplacements maximum atteint."
	if gems < cost:
		return "❌ Pas assez de gemmes !"
	gems -= cost
	mine_slot_count += 1
	save_game()
	return "✅ Nouvel emplacement débloqué !"

func mine_upgrade_cost() -> int:
	return mine_level * 30

func upgrade_mine() -> String:
	update_mine()
	var cost := mine_upgrade_cost()
	if gems < cost:
		return "❌ Pas assez de gemmes !"
	gems -= cost
	mine_level += 1
	mine_capacity += 10
	save_game()
	return "✅ Stockage amélioré → %d gemmes !" % mine_capacity

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED \
	or what == NOTIFICATION_WM_CLOSE_REQUEST \
	or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		update_mine()
		save_game()

func is_busy(mon: MonsterData) -> bool:
	return team.has(mon) or mine_slots.has(mon)

func discover(id: String) -> void:
	discovered[id] = true

func is_discovered(id: String) -> bool:
	return discovered.has(id)
