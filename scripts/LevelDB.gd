# LevelDB.gd  -> base de données des niveaux du mode Histoire (autoload "LevelDB")
# Créer un niveau = ajouter 1 ligne dans LEVELS.
#   id    : identifiant du monstre (voir MonsterDB)
#   lv    : niveau du monstre
#   turns : nombre de tours avant qu'il attaque
extends Node

const LEVELS := {
	1: [ {"id": "slime_feu", "lv": 6, "turns": 3} ],
	2: [ {"id": "slime_eau", "lv": 8, "turns": 3}, {"id": "slime_terre", "lv": 8, "turns": 4} ],
	3: [ {"id": "slime_vent", "lv": 10, "turns": 3}, {"id": "slime_lumiere", "lv": 10, "turns": 3}, {"id": "slime_tenebre", "lv": 12, "turns": 4} ],
}

# Nombre total de niveaux
func count() -> int:
	return LEVELS.size()

func has(level: int) -> bool:
	return LEVELS.has(level)

# Liste des ennemis d'un niveau (tableau vide si le niveau n'existe pas)
func get_enemies(level: int) -> Array:
	return LEVELS.get(level, [])
