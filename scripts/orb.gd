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
	var tex := Elements.orb_texture(element)
	if tex != null:
		$Sprite2D.texture = tex
		$Sprite2D.modulate = Color.WHITE
		# adapte la taille de l'orbe à la case (~130 px)
		var target := 130.0
		var s: float = target / float(max(tex.get_width(), tex.get_height()))
		$Sprite2D.scale = Vector2(s, s)
	else:
		# secours si une image manque : ancienne teinte
		$Sprite2D.modulate = Elements.orb_color(element)

# Petite animation quand l'orbe se replace (utile pour le "feel")
func move_to(target: Vector2, duration := 0.08) -> void:
	var tw := create_tween()
	tw.tween_property(self, "position", target, duration)\
	  .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _ready() -> void:
	$Area2D.input_pickable = false
