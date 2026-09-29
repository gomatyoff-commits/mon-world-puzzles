extends Node

var species := {}

func _ready() -> void:
	species = {
		"slime":         {"name": "Slime",            "el": Elements.E.NEUTRAL, "hp": 100, "atk": 10,  "rank": 0, "tex": "res://assets/monster/Slime.png"},
		"slime_feu":     {"name": "Slime de Feu",     "el": Elements.E.FIRE,    "hp": 300, "atk": 100, "rank": 1, "tex": "res://assets/monster/SlimeDeFeu.png"},
		"slime_eau":     {"name": "Slime d'Eau",      "el": Elements.E.WATER,   "hp": 300, "atk": 100, "rank": 1, "tex": "res://assets/monster/SlimeDEau.png"},
		"slime_terre":   {"name": "Slime de Terre",   "el": Elements.E.EARTH,   "hp": 300, "atk": 100, "rank": 1, "tex": "res://assets/monster/SlimeDeTerre.png"},
		"slime_vent":    {"name": "Slime de Vent",    "el": Elements.E.WIND,    "hp": 300, "atk": 100, "rank": 1, "tex": "res://assets/monster/SlimeDAir.png"},
		"slime_lumiere": {"name": "Slime de Lumière", "el": Elements.E.LIGHT,   "hp": 300, "atk": 100, "rank": 1, "tex": "res://assets/monster/SlimeDeLumiere.png"},
		"slime_tenebre": {"name": "Slime de Ténèbre", "el": Elements.E.DARK,    "hp": 300, "atk": 100, "rank": 1, "tex": "res://assets/monster/SlimeDesTenebres.png"},
	}

func has(id: String) -> bool:
	return species.has(id)

# Crée une instance de monstre depuis la bibliothèque
func create(id: String, level := 1, turns := 1) -> MonsterData:
	var s = species[id]
	var m := MonsterData.new(s["name"], s["el"], s["hp"], s["atk"], turns, s["tex"], level, s["rank"])
	m.species_id = id
	return m

func display_name(id: String) -> String:
	return species[id]["name"]
