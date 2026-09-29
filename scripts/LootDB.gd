extends Node

const MATERIALS := {
	"cristal_feu": "Cristal de Feu",
	"cristal_eau": "Cristal d'Eau",
	"cristal_terre": "Cristal de Terre",
	"cristal_vent": "Cristal de Vent",
	"cristal_lumiere": "Cristal de Lumière",
	"cristal_tenebre": "Cristal de Ténèbre",
}

# Tables de butin par identifiant (faciles à créer/étendre)
var tables := {
	"event_slime": { "material_chance": 0.5, "monster_id": "slime", "monster_chance": 0.25 },
}

func random_material() -> String:
	return MATERIALS.keys()[randi() % MATERIALS.size()]

# rolls = nombre de tirages de matériaux (ex: nombre de slimes affrontés)
# Renvoie { "materials": {id:count}, "monsters": [ids] }
func roll(table_id: String, rolls: int) -> Dictionary:
	var t = tables[table_id]
	var result := { "materials": {}, "monsters": [] }
	for i in rolls:
		if randf() < float(t["material_chance"]):
			var m := random_material()
			result["materials"][m] = int(result["materials"].get(m, 0)) + 1
	if randf() < float(t["monster_chance"]):
		result["monsters"].append(t["monster_id"])
	return result
