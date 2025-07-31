extends Sprite2D
class_name ShakingSprite


const SHAKE = 0.5
const DECAY = 0.8
const MAX_OFFSET = Vector2(160, 90)
const MAX_ROLL = 0.15
const TRAUMA_POWER = 2


@export var trauma_modifier: float = 1.0


var trauma = 0.0
var aim_rot = 0
var base_rotation = 0
@onready var noise = FastNoiseLite.new()
var noise_y = 0


@onready var shader_canvas = $ShaderCanvas


func _ready():
	randomize()
	noise.seed = randi()
	noise.frequency = 0.25


func _process(delta):
	if trauma:
		trauma = max(trauma - DECAY * delta / trauma_modifier, 0)
		shake()


func shake():
	# Based on https://kidscancode.org/godot_recipes/2d/screen_shake/
	
	var amount = pow(trauma * trauma_modifier, TRAUMA_POWER)
	
	offset[0] = MAX_OFFSET[0] * amount * noise.get_noise_1d(noise_y)
	offset[1] = MAX_OFFSET[1] * amount * noise.get_noise_1d(noise_y + 9999)
	
	noise_y += 1
