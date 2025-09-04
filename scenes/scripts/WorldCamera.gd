extends Camera2D
class_name WorldCamera


const TRANSITION_TIME = 2.0
const LERP_WEIGHT = 0.1

const SHAKE = 0.5
const DECAY = 0.8
const MAX_OFFSET = Vector2(320, 180)
const MAX_ROLL = 0.15
const TRAUMA_POWER = 2


@onready var center: Vector2 = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height")) / 2
@onready var aim_pos: Vector2 = center
var aim_node: Node2D = null
var aim_offset: Vector2 = Vector2(0, 0)

var trauma = 0.0
var aim_rot = 0
var base_rotation = 0
@onready var noise = FastNoiseLite.new()
var noise_y = 0
var next_process_position = null


func _ready():
	randomize()
	noise.seed = randi()
	noise.frequency = 0.25
	
	position = center


func _process(delta):
	if next_process_position != null:
		position = next_process_position
		next_process_position = null
	position = lerp(position, get_effective_aim_pos(), LERP_WEIGHT)
	
	if trauma:
		trauma = max(trauma - DECAY * delta, 0)
		shake()
	else:
		rotation = base_rotation


func add_trauma(amount = SHAKE):
	trauma = amount


func shake():
	# Based on https://kidscancode.org/godot_recipes/2d/screen_shake/
	
	var amount = pow(trauma, TRAUMA_POWER)
	
	rotation = base_rotation + MAX_ROLL * amount * noise.get_noise_1d(noise_y)
	offset[0] = MAX_OFFSET[0] * amount * noise.get_noise_1d(noise_y)
	offset[1] = MAX_OFFSET[1] * amount * noise.get_noise_1d(noise_y + 9999)
	
	noise_y += 1


func get_effective_aim_pos() -> Vector2:
	var effective_aim_pos = aim_pos
	if aim_node != null:
		effective_aim_pos = aim_node.global_position
	return effective_aim_pos + aim_offset


func follow_node(node: Node2D):
	aim_node = node


func follow_pos(pos: Vector2):
	aim_pos = pos


func snap_to_aim():
	position = get_effective_aim_pos()


func adjust(adjustment_vec):
	if aim_pos != null:
		aim_pos += adjustment_vec
	
	next_process_position = position + adjustment_vec
