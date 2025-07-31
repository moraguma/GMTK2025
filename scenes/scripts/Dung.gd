extends CharacterBody2D
class_name Dung


const THROW_SPEED = 1000.0
const NORMAL_TERMINAL_SPEED = 1800.0

const PICK_TIME = 0.25

const AIR_RESISTANCE = 0.012
const GRAVITY = 0.01


var active = false
var landed = true
var aiming = false
var player: Beetle = null


@onready var pick_timer: Timer = $PickTimer
@onready var collection_area: Area2D = $CollectionArea
@onready var sprite: ShakingSprite = $Sprite


func _physics_process(delta: float) -> void:
	_movement_process(delta)


func _movement_process(delta: float) -> void:
	if not active or landed or aiming: 
		return
	
	# Air resistance
	velocity[0] = lerp(velocity[0], 0.0, AIR_RESISTANCE)
	
	# Gravity
	velocity[1] = lerp(velocity[1], NORMAL_TERMINAL_SPEED, GRAVITY)
	
	if move_and_slide():
		landed = true


## Throws dung, starting from player, in given direction
func throw(dir, on_fire=false):
	activate()
	pick_timer.start(PICK_TIME)
	
	position = player.position
	velocity = dir * THROW_SPEED


## Called when player enters collection area. deactivates and gives player dung
func collect(body):
	if not pick_timer.is_stopped():
		return
	
	body.get_dung()
	deactivate()


func activate():
	active = true
	landed = false
	
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)
	collection_area.set_collision_mask_value(2, true)
	show()


func deactivate():
	active = false
	
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)
	collection_area.set_collision_mask_value(2, false)
	hide()
