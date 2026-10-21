# SkillDB.gd  (Autoload -> "SkillDB")
extends Node

# type : comportement de la compétence (on en ajoutera d'autres plus tard)
const SKILLS := {
	"charge": {
		"name": "Charge",
		"cooldown": 3,
		"type": "damage_single",
		"mult": 2.0,
		"desc": "Inflige ATK x2 à un ennemi (bonus/malus élémentaire).",
	},
}

func has(id: String) -> bool:
	return SKILLS.has(id)

func get_skill(id: String) -> Dictionary:
	return SKILLS.get(id, {})

func cooldown(id: String) -> int:
	return int(SKILLS[id]["cooldown"]) if SKILLS.has(id) else 0

# "Charge" pour un neutre, "Charge Feu", "Charge Eau"... sinon
func display_name(id: String, element: int) -> String:
	if not SKILLS.has(id):
		return ""
	var n: String = SKILLS[id]["name"]
	if element == Elements.E.NEUTRAL:
		return n
	return "%s %s" % [n, Elements.NAMES[element]]
