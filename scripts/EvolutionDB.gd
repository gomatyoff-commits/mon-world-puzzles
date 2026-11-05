# EvolutionDB.gd  -> base de données des évolutions (autoload "EvolutionDB")
# Clé = species_id du monstre de départ (voir MonsterDB), en minuscules.
#   to_id     : monstre obtenu (id de MonsterDB)
#   min_level : niveau minimum requis
#   fodder    : nombre de monstres à sacrifier
#   material  : matériau requis (id de LootDB.MATERIALS)
extends Node

const EVOLUTIONS := {
	"slime": [
		{ "to_id": "slime_feu",        "min_level": 10, "fodder": 1, "material": "cristal_feu" },
		{ "to_id": "slime_eau",        "min_level": 10, "fodder": 1, "material": "cristal_eau" },
		{ "to_id": "slime_terre",      "min_level": 10, "fodder": 1, "material": "cristal_terre" },
		{ "to_id": "slime_vent",       "min_level": 10, "fodder": 1, "material": "cristal_vent" },
		{ "to_id": "slime_lumiere",    "min_level": 10, "fodder": 1, "material": "cristal_lumiere" },
		{ "to_id": "slime_tenebre",    "min_level": 10, "fodder": 1, "material": "cristal_tenebre" },
		{ "to_id": "slime_incubateur", "min_level": 10, "fodder": 1, "material": "embryon" },
	],
	"slime_feu": [
		{ "to_id": "slime_magma",   "min_level": 20, "fodder": 1, "material": "cristal_feu" },
	],
	"slime_eau": [
		{ "to_id": "slime_glace",   "min_level": 20, "fodder": 1, "material": "cristal_eau" },
	],
	"slime_terre": [
		{ "to_id": "slime_cristal", "min_level": 20, "fodder": 1, "material": "cristal_terre" },
	],
	"slime_vent": [
		{ "to_id": "slime_foudre",  "min_level": 20, "fodder": 1, "material": "cristal_vent" },
	],
	"slime_lumiere": [
		{ "to_id": "slime_sacre",   "min_level": 20, "fodder": 1, "material": "cristal_lumiere" },
	],
	"slime_tenebre": [
		{ "to_id": "slime_neant",   "min_level": 20, "fodder": 1, "material": "cristal_tenebre" },
	],
}

# Évolutions possibles pour une espèce (tableau vide si aucune)
func get_for(species_id: String) -> Array:
	return EVOLUTIONS.get(species_id, [])

func has_evolution(species_id: String) -> bool:
	return EVOLUTIONS.has(species_id)
