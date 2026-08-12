# orb.gd
extends Node2D
class_name Orb

var element: int          # une valeur de Elements.E (parmi les 6 orbes)
var grid_pos: Vector2i    # position logique dans la grille

func setup(elem: int, gpos: Vector2i) -> void:
	element = elem
	grid_pos = gpos
	_refresh_visual()

func _refresh_visual() -> void:
	# Version prototype : on colore le sprite avec la couleur de l'élément.
	# Remplace par $Sprite2D.texture = ... quand tu auras tes vrais sprites.
	$Sprite2D.modulate = Elements.orb_color(element)

# Petite animation quand l'orbe se replace (utile pour le "feel")
func move_to(target: Vector2, duration := 0.08) -> void:
	var tw := create_tween()
	tw.tween_property(self, "position", target, duration)\
	  .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _ready() -> void:
	$Area2D.input_pickable = false
