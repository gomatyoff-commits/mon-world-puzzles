# LevelDB.gd  -> base de données des niveaux du mode Histoire (autoload "LevelDB")
#
# Chaque niveau = des VAGUES. Chaque vague est tirée AU HASARD dans la "pool"
# du niveau, donc deux parties du même niveau ne donnent pas les mêmes monstres.
#
#   waves : nombre de monstres pour chaque vague
#           ex. [3, 3]    -> 2 vagues de 3 monstres
#               [2, 3, 1] -> 3 vagues : 2 monstres, puis 3, puis 1 (boss ?)
#   pool  : monstres qui peuvent apparaître dans ce niveau
#           id    : identifiant du monstre (voir MonsterDB)
#           lv    : niveau du monstre
#           turns : nombre de tours avant qu'il attaque
#
# Dans une même vague, un monstre n'apparaît qu'une fois (sauf si la pool
# est plus petite que la vague). D'une vague à l'autre, il peut revenir.
extends Node

const LEVELS := {
	1: {
		"waves": [3, 3],
		"pool": [
			{"id": "slime",       "lv": 4, "turns": 3},
			{"id": "slime_feu",   "lv": 6, "turns": 3},
			{"id": "slime_eau",   "lv": 6, "turns": 3},
			{"id": "slime_vent",  "lv": 6, "turns": 3},
			{"id": "slime_terre", "lv": 6, "turns": 3},
			{"id": "slime_lumiere", "lv": 6, "turns": 3},
			{"id": "slime_tenebre", "lv": 6, "turns": 3},
		],
	},
	2: {
		"waves": [2, 3, 3],
		"pool": [
			{"id": "slime",       "lv": 6, "turns": 3},
			{"id": "slime_feu",   "lv": 8, "turns": 3},
			{"id": "slime_eau",   "lv": 8, "turns": 3},
			{"id": "slime_vent",  "lv": 8, "turns": 3},
			{"id": "slime_terre", "lv": 8, "turns": 3},
			{"id": "slime_lumiere", "lv": 8, "turns": 3},
			{"id": "slime_tenebre", "lv": 8, "turns": 3},
		],
	},
	3: {
		"waves": [3, 3, 3],
		"pool": [
			{"id": "slime",       "lv": 8, "turns": 3},
			{"id": "slime_feu",   "lv": 10, "turns": 3},
			{"id": "slime_eau",   "lv": 10, "turns": 3},
			{"id": "slime_vent",  "lv": 10, "turns": 3},
			{"id": "slime_terre", "lv": 10, "turns": 3},
			{"id": "slime_lumiere", "lv": 10, "turns": 3},
			{"id": "slime_tenebre", "lv": 10, "turns": 3},
		],
	},
}

# Nombre total de niveaux
func count() -> int:
	return LEVELS.size()

func has(level: int) -> bool:
	return LEVELS.has(level)

# Nombre de vagues d'un niveau
func wave_count(level: int) -> int:
	if not LEVELS.has(level):
		return 1
	return max(1, LEVELS[level]["waves"].size())

# Tire au hasard les ennemis d'une vague (wave commence à 1).
# Renvoie une liste de { id, lv, turns }.
func roll_wave(level: int, wave: int) -> Array:
	if not LEVELS.has(level):
		return []
	var data: Dictionary = LEVELS[level]
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
