# LevelDB.gd  -> base de données des MONDES et de leurs NIVEAUX (autoload "LevelDB")
#
# WORLDS = { n° monde : { name, levels = { n° niveau : {...} } } }
# Les mondes et les niveaux se débloquent dans l'ordre (voir GameManager).
#
# Chaque niveau = des VAGUES tirées AU HASARD dans la "pool" du niveau,
# donc deux parties du même niveau ne donnent pas les mêmes monstres.
#   waves : nombre de monstres pour chaque vague
#           ex. [3, 3]    -> 2 vagues de 3 monstres
#               [2, 3, 1] -> 3 vagues : 2 monstres, puis 3, puis 1
#   pool  : monstres qui peuvent apparaître dans ce niveau
#           id    : identifiant du monstre (voir MonsterDB)
#           lv    : niveau du monstre
#           turns : nombre de tours avant qu'il attaque
#
# Dans une même vague, un monstre n'apparaît qu'une fois (sauf si la pool
# est plus petite que la vague). D'une vague à l'autre, il peut revenir.
extends Node

const WORLDS := {
	1: {
		"name": "Plaine des Slimes",
		"levels": {
			1: {
				"waves": [3, 3],
				"pool": [
					{"id": "slime",       "lv": 5, "turns": 3},
					{"id": "slime_feu",   "lv": 6, "turns": 3},
					{"id": "slime_eau",   "lv": 6, "turns": 3},
					{"id": "slime_vent",  "lv": 6, "turns": 3},
					{"id": "slime_terre", "lv": 6, "turns": 3},
				],
			},
			2: {
				"waves": [2, 3, 3],
				"pool": [
					{"id": "slime_feu",     "lv": 8, "turns": 3},
					{"id": "slime_eau",     "lv": 8, "turns": 3},
					{"id": "slime_vent",    "lv": 8, "turns": 3},
					{"id": "slime_terre",   "lv": 8, "turns": 4},
					{"id": "slime_lumiere", "lv": 8, "turns": 3},
					{"id": "slime_tenebre", "lv": 8, "turns": 3},
				],
			},
			3: {
				"waves": [3, 3, 3],
				"pool": [
					{"id": "slime_vent",    "lv": 10, "turns": 3},
					{"id": "slime_lumiere", "lv": 10, "turns": 3},
					{"id": "slime_tenebre", "lv": 12, "turns": 4},
					{"id": "slime_feu",     "lv": 10, "turns": 3},
					{"id": "slime_eau",     "lv": 10, "turns": 3},
					{"id": "slime_terre",   "lv": 10, "turns": 4},
				],
			},
		},
	},
	2: {
		"name": "Terres Élémentaires",
		"levels": {
			1: {
				"waves": [3, 3],
				"pool": [
					{"id": "slime_feu",     "lv": 15, "turns": 3},
					{"id": "slime_eau",     "lv": 15, "turns": 3},
					{"id": "slime_vent",    "lv": 15, "turns": 3},
					{"id": "slime_terre",   "lv": 15, "turns": 4},
					{"id": "slime_lumiere", "lv": 15, "turns": 3},
					{"id": "slime_tenebre", "lv": 15, "turns": 3},
				],
			},
			2: {
				"waves": [3, 3, 3],
				"pool": [
					{"id": "slime_feu",        "lv": 18, "turns": 3},
					{"id": "slime_eau",        "lv": 18, "turns": 3},
					{"id": "slime_terre",      "lv": 18, "turns": 4},
					{"id": "slime_incubateur", "lv": 18, "turns": 3},
					{"id": "slime_magma",      "lv": 12, "turns": 4},
					{"id": "slime_glace",      "lv": 12, "turns": 4},
				],
			},
			3: {
				"waves": [3, 3, 2],
				"pool": [
					{"id": "slime_magma",   "lv": 20, "turns": 4},
					{"id": "slime_glace",   "lv": 20, "turns": 4},
					{"id": "slime_cristal", "lv": 20, "turns": 4},
					{"id": "slime_foudre",  "lv": 20, "turns": 4},
					{"id": "slime_sacre",   "lv": 20, "turns": 4},
					{"id": "slime_neant",   "lv": 20, "turns": 4},
				],
			},
		},
	},
}

# --- MONDES ---
func world_count() -> int:
	return WORLDS.size()

func has_world(world: int) -> bool:
	return WORLDS.has(world)

func world_name(world: int) -> String:
	return str(WORLDS[world]["name"]) if WORLDS.has(world) else "???"

# --- NIVEAUX ---
func level_count(world: int) -> int:
	return WORLDS[world]["levels"].size() if WORLDS.has(world) else 0

func has(world: int, level: int) -> bool:
	return WORLDS.has(world) and WORLDS[world]["levels"].has(level)

func _level(world: int, level: int) -> Dictionary:
	return WORLDS[world]["levels"][level] if has(world, level) else {}

# Niveau qui suit (world, level) : niveau suivant du monde, sinon 1er niveau
# du monde suivant. Vector2i(-1, -1) s'il n'y a plus rien après.
func next_level(world: int, level: int) -> Vector2i:
	if has(world, level + 1):
		return Vector2i(world, level + 1)
	if has(world + 1, 1):
		return Vector2i(world + 1, 1)
	return Vector2i(-1, -1)

# Nombre de vagues d'un niveau
func wave_count(world: int, level: int) -> int:
	var data := _level(world, level)
	if data.is_empty():
		return 1
	return max(1, data["waves"].size())

# Tire au hasard les ennemis d'une vague (wave commence à 1).
# Renvoie une liste de { id, lv, turns }.
func roll_wave(world: int, level: int, wave: int) -> Array:
	var data := _level(world, level)
	if data.is_empty():
		return []
	var pool: Array = data["pool"]
	if pool.is_empty():
		return []
	var sizes: Array = data["waves"]
	var nb: int = int(sizes[clamp(wave - 1, 0, sizes.size() - 1)])

	var result: Array = []
	var bag: Array = []
	for i in nb:
		if bag.is_empty():          # sac vide -> on remet toute la pool, mélangée
			bag = pool.duplicate()
			bag.shuffle()
		result.append(bag.pop_back())
	return result
