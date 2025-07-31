extends CharacterBody2D
class_name Beetle


const DUNG_SCENE = preload("res://scenes/Dung.tscn")

const NORMAL_TERMINAL_SPEED = 1800.0
const JUMP_SPEED = -700.0
const SPEED = {
	false: 350.0,
	true: 250.0
}
const UP_SLOPE_SPEED = {
	false: 500.0,
	true: 300.0
}
const DOWN_SLOPE_SPEED = {
	false: 350.0,
	true: 200.0
}


const GRAVITY = 0.01
const AIR_ACCELERATION = 0.0
const ACCELERATIONS = {
	false: 0.1,
	true: 0.04
}
const DECELERATIONS = {
	false: 0.2,
	true: 0.08
}


var dung: Dung
var has_dung = true
var aiming = false

var is_grounded = true


@onready var left_feet_cast: RayCast2D = $LeftFeetCast
@onready var right_feet_cast: RayCast2D = $RightFeetCast


func _ready() -> void:
	dung = DUNG_SCENE.instantiate()
	dung.player = self
	get_parent().add_child.call_deferred(dung)
	dung.deactivate.call_deferred()


func _physics_process(delta: float) -> void:
	_movement_process(delta)


func _movement_process(delta: float) -> void:
	# Throw logic
	if Input.is_action_just_pressed("aim") and not aiming: # TODO add aiming reticle
		aiming = true
		dung.aiming = true
	
	if aiming:
		if Input.is_action_just_pressed("throw") and has_dung:
			dung.throw((get_global_mouse_position() - global_position).normalized())
			lose_dung()
			
			aiming = false
			dung.aiming = false
		elif Input.is_action_just_released("aim"):
			aiming = false
			dung.aiming = false
		else:
			return
	
	# Movement logic
	var dir = Input.get_vector("left", "right", "up", "down")
	
	# Horizontal movement
	var feet_raycast_distances = get_feet_raycast_movements()
	var slope_dir = 0 # Direction of slope ascent
	if feet_raycast_distances[0] > feet_raycast_distances[1]:
		slope_dir = 1
	elif feet_raycast_distances[0] < feet_raycast_distances[1]:
		slope_dir = -1
	
	var speed_dict = SPEED
	if slope_dir * dir[0] > 0:
		speed_dict = UP_SLOPE_SPEED
	elif slope_dir * dir[0] < 0:
		speed_dict = DOWN_SLOPE_SPEED
	
	var speed = speed_dict[has_dung]
	var accel = (ACCELERATIONS if dir.dot(velocity) > 0 else DECELERATIONS)[has_dung] if is_grounded else AIR_ACCELERATION
	velocity[0] = lerp(velocity[0], dir[0] * speed, accel)
	
	# Vertical movement
	var gravity = GRAVITY
	var terminal_speed = NORMAL_TERMINAL_SPEED
	velocity[1] = lerp(velocity[1], terminal_speed, gravity)
	
	var jumped = false
	if not has_dung and is_grounded and Input.is_action_just_pressed("jump"):
		jumped = true
		velocity[1] += JUMP_SPEED
	
	var was_grounded = is_grounded
	move_and_slide()
	is_grounded = is_on_floor()
	
	# Floor correction
	if was_grounded and not is_on_floor() and not jumped:
		var movement_options = get_feet_raycast_movements()
		
		if len(movement_options) > 0:
			var min_movement = movement_options[0]
			var min_movement_length = min_movement.length()
			for i in range(1, len(movement_options)):
				var movement_length = movement_options[i].length()
				if movement_length < min_movement_length:
					min_movement = movement_options[i]
					min_movement_length = movement_length
			
			if min_movement[1] > 0:
				position += min_movement
				is_grounded = true


func get_feet_raycast_movements():
	var movement_options = []
	for cast: RayCast2D in [left_feet_cast, right_feet_cast]:
		cast.force_raycast_update()
		if cast.is_colliding():
			movement_options.append(cast.get_collision_point() - cast.global_position)
		else:
			movement_options.append(Vector2(0, -1))
	return movement_options


func lose_dung():
	has_dung = false


func get_dung():
	has_dung = true
