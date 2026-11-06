# LootDB.gd  -> matériaux + butin de chaque monstre (autoload "LootDB")
extends Node

const MATERIALS := {
	"cristal_feu": "Cristal de Feu",
	"cristal_eau": "Cristal d'Eau",
	"cristal_terre": "Cristal de Terre",
	"cristal_vent": "Cristal de Vent",
	"cristal_lumiere": "Cristal de Lumière",
	"cristal_tenebre": "Cristal de Ténèbre",
	"embryon": "Embryon",
}

# --- BUTIN PAR MONSTRE ---
# Clé = species_id (voir MonsterDB). Chaque monstre vaincu tire CHAQUE ligne.
#   material : id d'un matériau (MATERIALS), ou "random" = matériau au hasard
#   monster  : id d'un monstre à recruter (au lieu d'un matériau)
#   chance   : probabilité de 0.0 à 1.0  (0.25 = 1 chance sur 4)
#   count    : quantité donnée (défaut 1)
# Un monstre absent de cette liste ne lâche rien (à part les pièces).
const DROPS := {
	"slime": [
		{ "material": "random", "chance": 0.5 },
		{ "monster": "slime",   "chance": 0.25 },
	],
	# --- Rang 1 ---
	"slime_feu":     [ { "material": "cristal_feu",     "chance": 0.3 } ],
	"slime_eau":     [ { "material": "cristal_eau",     "chance": 0.3 } ],
	"slime_terre":   [ { "material": "cristal_terre",   "chance": 0.3 } ],
	"slime_vent":    [ { "material": "cristal_vent",    "chance": 0.3 } ],
	"slime_lumiere": [ { "material": "cristal_lumiere", "chance": 0.3 } ],
	"slime_tenebre": [ { "material": "cristal_tenebre", "chance": 0.3 } ],
	"slime_incubateur": [
		{ "material": "embryon", "chance": 0.3 },
		{ "monster": "slime",    "chance": 0.15 },
	],
	# --- Rang 2 ---
	"slime_magma":   [ { "material": "cristal_feu",     "chance": 0.6, "count": 2 } ],
	"slime_glace":   [ { "material": "cristal_eau",     "chance": 0.6, "count": 2 } ],
	"slime_cristal": [ { "material": "cristal_terre",   "chance": 0.6, "count": 2 } ],
	"slime_foudre":  [ { "material": "cristal_vent",    "chance": 0.6, "count": 2 } ],
	"slime_sacre":   [ { "material": "cristal_lumiere", "chance": 0.6, "count": 2 } ],
	"slime_neant":   [ { "material": "cristal_tenebre", "chance": 0.6, "count": 2 } ],
}

func random_material() -> String:
	return MATERIALS.keys()[randi() % MATERIALS.size()]

# Tire le butin d'UN monstre vaincu.
# Renvoie { "materials": {id: quantité}, "monsters": [ids] }
func roll_monster(species_id: String) -> Dictionary:
	var result := { "materials": {}, "monsters": [] }
	for d in DROPS.get(species_id, []):
		if randf() >= float(d.get("chance", 0.0)):
			continue
		var n := int(d.get("count", 1))
		if d.has("monster"):
			for i in n:
				result["monsters"].append(str(d["monster"]))
		elif d.has("material"):
			var id := str(d["material"])
			if id == "random":
				id = random_material()
			result["materials"][id] = int(result["materials"].get(id, 0)) + n
	return result
