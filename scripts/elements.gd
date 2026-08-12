# elements.gd  (Autoload -> "Elements")
extends Node

# --- Les 7 éléments (l'ordre compte pour l'indexation) ---
enum E { FIRE, WATER, EARTH, WIND, LIGHT, DARK, NEUTRAL }

# --- Les 6 orbes correspondent aux 6 premiers éléments ---
# (pas d'orbe NEUTRAL sur le board)
const ORB_ELEMENTS := [E.FIRE, E.WATER, E.EARTH, E.WIND, E.LIGHT, E.DARK]

# --- Couleurs d'affichage (pratique pour le prototypage sans sprites) ---
const COLORS := {
	E.FIRE:    Color("#e74c3c"),  # rouge
	E.WATER:   Color("#3498db"),  # bleu
	E.EARTH:   Color("#27ae60"),  # vert
	E.WIND:    Color("#1abc9c"),  # cyan/turquoise
	E.LIGHT:   Color("#f1c40f"),  # jaune
	E.DARK:    Color("#8e44ad"),  # violet
	E.NEUTRAL: Color("#bdc3c7"),  # gris
}

const NAMES := {
	E.FIRE: "Feu", E.WATER: "Eau", E.EARTH: "Terre", E.WIND: "Vent",
	E.LIGHT: "Lumière", E.DARK: "Ténèbres", E.NEUTRAL: "Neutre"
}

# --- TABLE DE FAIBLESSE / RÉSISTANCE ---
# Cycle : Feu -> Terre -> Eau -> Vent -> Feu
# Miroir : Lumière <-> Ténèbres
# "attaquant bat défenseur" (le défenseur est FAIBLE face à l'attaquant)
const STRONG_AGAINST := {
	E.FIRE:  E.EARTH,   # Feu bat Terre
	E.EARTH: E.WATER,   # Terre bat Eau
	E.WATER: E.WIND,    # Eau bat Vent
	E.WIND:  E.FIRE,    # Vent bat Feu
	E.LIGHT: E.DARK,    # Lumière bat Ténèbres
	E.DARK:  E.LIGHT,   # Ténèbres bat Lumière
	# NEUTRAL : aucune force
}

# Multiplicateur de dégâts attaquant -> défenseur
const MULT_STRONG := 2.0   # super efficace
const MULT_WEAK   := 0.5   # peu efficace
const MULT_NORMAL := 1.0

func get_multiplier(attacker: int, defender: int) -> float:
	# L'attaquant est fort contre le défenseur ?
	if STRONG_AGAINST.get(attacker, -1) == defender:
		return MULT_STRONG
	# L'attaquant est faible ? (= le défenseur est fort contre l'attaquant)
	if STRONG_AGAINST.get(defender, -1) == attacker:
		return MULT_WEAK
	return MULT_NORMAL

func orb_color(orb_element: int) -> Color:
	return COLORS[orb_element]
