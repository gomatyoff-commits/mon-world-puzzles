extends RefCounted
class_name MonsterData

const MAX_LEVEL := 100
const GROWTH := 0.05

var mon_name: String
var element: int
var base_hp: int
var base_atk: int
var base_def: int
var texture_path: String = ""
var texture: Texture2D
var turn_counter: int
var level: int = 1
var xp: int = 0
var hp: int = 0
var rank: int = 0
var species_id: String = ""

func _init(p_name: String, p_element: int, p_base_hp: int, p_base_atk: int, p_base_def: int,
		   p_turns := 1, p_texture_path := "", p_level := 1, p_rank := 0) -> void:
	mon_name = p_name
	element = p_element
	base_hp = p_base_hp
	base_atk = p_base_atk
	base_def = p_base_def
	turn_counter = p_turns
	texture_path = p_texture_path
	texture = load(p_texture_path) if p_texture_path != "" else load("res://icon.svg")
	level = p_level
	rank = p_rank
	hp = max_hp

var max_hp: int:
	get: return int(round(base_hp * (1.0 + (level - 1) * GROWTH)))

var atk: int:
	get: return int(round(base_atk * (1.0 + (level - 1) * GROWTH)))

var defense: int:
	get: return int(round(base_def * (1.0 + (level - 1) * GROWTH)))

func is_alive() -> bool:
	return hp > 0

func xp_to_next() -> int:
	return level * 50

func add_xp(amount: int) -> void:
	if level >= MAX_LEVEL: return
	xp += amount
	while level < MAX_LEVEL and xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1

# XP donnée quand ce monstre est sacrifié en fusion
func fusion_value() -> int:
	return 50 + level * 25 + xp
