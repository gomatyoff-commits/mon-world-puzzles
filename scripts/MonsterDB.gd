extends Node

var species := {}

func _ready() -> void:
	species = {
		"slime":         {"name": "Slime",            "el": Elements.E.NEUTRAL, "hp": 100, "atk": 10,  "def": 0,  "rank": 0, "work": 1, "skill": "charge", "tex": "res://assets/monster/Slime.png"},
		"slime_feu":     {"name": "Slime de Feu",     "el": Elements.E.FIRE,    "hp": 300, "atk": 100, "def": 10, "rank": 1, "work": 5, "skill": "charge", "tex": "res://assets/monster/SlimeDeFeu.png"},
		"slime_eau":     {"name": "Slime d'Eau",      "el": Elements.E.WATER,   "hp": 300, "atk": 100, "def": 10, "rank": 1, "work": 5, "skill": "charge", "tex": "res://assets/monster/SlimeDEau.png"},
		"slime_terre":   {"name": "Slime de Terre",   "el": Elements.E.EARTH,   "hp": 300, "atk": 100, "def": 10, "rank": 1, "work": 5, "skill": "charge", "tex": "res://assets/monster/SlimeDeTerre.png"},
		"slime_vent":    {"name": "Slime de Vent",    "el": Elements.E.WIND,    "hp": 300, "atk": 100, "def": 10, "rank": 1, "work": 5, "skill": "charge", "tex": "res://assets/monster/SlimeDeVent.png"},
		"slime_lumiere": {"name": "Slime de Lumière", "el": Elements.E.LIGHT,   "hp": 300, "atk": 100, "def": 10, "rank": 1, "work": 5, "skill": "charge", "tex": "res://assets/monster/SlimeDeLumiere.png"},
		"slime_tenebre": {"name": "Slime de Ténèbre", "el": Elements.E.DARK,    "hp": 300, "atk": 100, "def": 10, "rank": 1, "work": 5, "skill": "charge", "tex": "res://assets/monster/SlimeDesTenebres.png"},
		"slime_incubateur":         {"name": "Slime Incubateur", "el": Elements.E.NEUTRAL, "hp": 300, "atk": 50,  "def": 20, "rank": 1, "work": 5, "skill": "charge", "tex": "res://assets/monster/SlimeIncubateur.png"},
		"slime_magma":         {"name": "Slime Magma", "el": Elements.E.FIRE, "hp": 500, "atk": 300,  "def": 50, "rank": 2, "work": 15, "skill": "charge", "tex": "res://assets/monster/SlimeMagma.png"},
		"slime_glace":         {"name": "Slime de Glace", "el": Elements.E.WATER, "hp": 500, "atk": 300,  "def": 50, "rank": 2, "work": 15, "skill": "charge", "tex": "res://assets/monster/SlimeDeGlace.png"},
		"slime_cristal":         {"name": "Slime de Cristal", "el": Elements.E.EARTH, "hp": 500, "atk": 300,  "def": 50, "rank": 2, "work": 15, "skill": "charge", "tex": "res://assets/monster/SlimeDeCristal.png"},
		"slime_foudre":         {"name": "Slime de Foudre", "el": Elements.E.WIND, "hp": 500, "atk": 300,  "def": 50, "rank": 2, "work": 15, "skill": "charge", "tex": "res://assets/monster/SlimeDeFoudre.png"},
		"slime_sacre":         {"name": "Slime Sacré", "el": Elements.E.LIGHT, "hp": 500, "atk": 300,  "def": 50, "rank": 2, "work": 15, "skill": "charge", "tex": "res://assets/monster/SlimeSacre.png"},
		"slime_neant":         {"name": "Slime du Néant", "el": Elements.E.DARK, "hp": 500, "atk": 300,  "def": 50, "rank": 2, "work": 15, "skill": "charge", "tex": "res://assets/monster/SlimeDuNeant.png"},
	}

func has(id: String) -> bool:
	return species.has(id)

# Crée une instance de monstre depuis la bibliothèque
func create(id: String, level := 1, turns := 1) -> MonsterData:
	var s = species[id]
	var m := MonsterData.new(s["name"], s["el"], s["hp"], s["atk"], s["def"], turns, s["tex"], level, s["rank"])
	m.species_id = id
	m.base_def = int(s.get("def", 0))
	m.work = int(s.get("work", 1))
	m.skill_id = str(s.get("skill", ""))
	return m

func display_name(id: String) -> String:
	return species[id]["name"]
