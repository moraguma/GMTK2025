extends CharacterBody2D
class_name Dung


const THROW_SPEED = 1500.0
const FIRE_SPEED = 1300.0
const NORMAL_TERMINAL_SPEED = 3400.0

const PICK_TIME = 0.5

const AIR_RESISTANCE = 0.012
const GRAVITY = 0.01


var active = false
var landed = true
var aiming = false
var player: Beetle = null
var on_fire = false


@onready var pick_timer: Timer = $PickTimer
@onready var collection_area: Area2D = $CollectionArea
@onready var sprite: ShakingSprite = $Sprite
@onready var fire: Sprite2D = $Fire


func _physics_process(delta: float) -> void:
	_movement_process(delta)
	_animation_process(delta)


func _movement_process(delta: float) -> void:
	if not active or landed or aiming: 
		return
	
	# Air resistance
	velocity[0] = lerp(velocity[0], 0.0, AIR_RESISTANCE)
	
	# Gravity
	velocity[1] = lerp(velocity[1], NORMAL_TERMINAL_SPEED, GRAVITY)
	
	if move_and_slide():
		landed = true
		on_fire = false


func _animation_process(delta: float) -> void:
	fire.visible = on_fire


## Throws dung, starting from player, in given direction
func throw(dir, catch_fire=false):
	activate()
	pick_timer.start(PICK_TIME)
	on_fire = catch_fire
	
	position = player.position
	velocity = dir * (FIRE_SPEED if on_fire else THROW_SPEED)


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


func destroy_leaf(body: Node2D) -> void:
	body.destroy()
