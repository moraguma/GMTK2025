extends CharacterBody2D
class_name Beetle


const DUNG_SCENE = preload("res://scenes/Dung.tscn")

const RAYCAST_DIF_FOR_ROLLING_JUMP = 64
const NORMAL_TERMINAL_SPEED = 1800.0
const FIRE_TERMINAL_SPEED = 2300.0
const JUMP_SPEED = -700.0
const ROLLING_JUMP_SPEED = -1000.0
const SOMERSAULT_VEC = Vector2(-50, -1000)
const FIRE_HIT_VEC = Vector2(-200, -1000)
const THROW_SPEED = 500.0
const FIRE_THROW_SPEED = 700.0
const CATCH_SPEED = 850.0
const MAX_HORIZONTAL_JUMP_SPEED = 200.0
const ROLLING_SPEED = 800.0
const UP_SLOPE_ROLLING_SPEED = 1150.0
const DOWN_SLOPE_ROLLING_SPEED = 800.0
const SPEED = {
	false: 420.0,
	true: 250.0
}
const UP_SLOPE_SPEED = {
	false: 600.0,
	true: 360.0
}
const DOWN_SLOPE_SPEED = {
	false: 420.0,
	true: 250.0
}

const GRAVITY = 0.01
const ROLLING_GRAVITY = 0.005
const AIR_ACCELERATION = 0.0
const ACCELERATIONS = {
	false: 0.1,
	true: 0.04
}
const DECELERATIONS = {
	false: 0.2,
	true: 0.04
}


const TIME_FOR_PRAY_PULL = 3.0

const HEIGHT_FOR_FIRE = 550.0
const PRAY_PULL_MAX_DIST = 600.0
const MAX_GROUNDED_THROW_ANGLE = PI / 3
const TOLERANCE = 0.001


var dung: Dung
var world_camera: WorldCamera
var world_loader: WorldLoader
var has_dung = true
var on_fire = false
var rolling = false
var rolling_uphill = false
var rolling_dir = 1
var aiming = false
var facing_dir = 1
var heavy_falling_height = null
var time_aiming_started = null
var can_pray_pull = false
var has_pray_pulled = false
var skip_floor_correction = false

var is_grounded = true


@onready var fire: Sprite2D = $Fire
@onready var sprite: Sprite2D = $Sprite
@onready var left_feet_cast: RayCast2D = $LeftFeetCast
@onready var right_feet_cast: RayCast2D = $RightFeetCast
@onready var dung_detector: RayCast2D = $DungDetector
@onready var arrow_pivot: Node2D = $ArrowPivot


func _ready() -> void:
	dung = DUNG_SCENE.instantiate()
	dung.player = self
	get_parent().add_child.call_deferred(dung)
	dung.deactivate.call_deferred()


func _physics_process(delta: float) -> void:
	_movement_process(delta)
	_animation_process(delta)


func _movement_process(delta: float) -> void:
	# Fire logic
	if has_dung and not is_grounded:
		if heavy_falling_height == null or position[1] < heavy_falling_height:
			heavy_falling_height = position[1]
		
		if position[1] - heavy_falling_height >= HEIGHT_FOR_FIRE:
			on_fire = true
	else:
		heavy_falling_height = null
	
	# Throw logic
	if Input.is_action_just_pressed("aim") and not aiming and not rolling: # Start aim
		time_aiming_started = Time.get_ticks_msec()
		aiming = true
		dung.aiming = true
		
		if has_dung:
			arrow_pivot.show()
		
		can_pray_pull = false
		if not has_dung and dung.landed and (is_grounded or not has_pray_pulled) and (dung.position - position).length() < PRAY_PULL_MAX_DIST:
			dung_detector.target_position = dung.position - position
			dung_detector.force_raycast_update()
			if not dung_detector.is_colliding():
				can_pray_pull = true
	
	var stop_aiming = func():
		aiming = false
		dung.aiming = false
		arrow_pivot.hide()
	
	var jumped = false
	if aiming and can_pray_pull: # Pray pull
		var time_elapsed = (Time.get_ticks_msec() - time_aiming_started) / 1000.0
		dung.sprite.trauma = time_elapsed / TIME_FOR_PRAY_PULL
		
		if time_elapsed >= TIME_FOR_PRAY_PULL:
			dung.deactivate()
			get_dung()
			stop_aiming.call()
			
			var pray_dir = (position - dung.position).normalized()
			velocity = pray_dir * CATCH_SPEED
			
			facing_dir = 1 if pray_dir[0] < 0 else -1
			
			if is_grounded:
				velocity[1] = 0
			else:
				has_pray_pulled = true
	
	if aiming: # Aima actions
		var throw_dir = (world_loader.get_global_mouse_position() - (Vector2(960, 540) + global_position - world_camera.get_screen_center_position())).normalized()
		if is_grounded:
			var angle = clamp(Vector2(0, -1).angle_to(throw_dir), -MAX_GROUNDED_THROW_ANGLE, MAX_GROUNDED_THROW_ANGLE)
			throw_dir = Vector2(0, -1).rotated(angle)
		
		arrow_pivot.rotation = Vector2(0, -1).angle_to(throw_dir)
		
		if Input.is_action_just_pressed("throw") and has_dung:
			dung.throw(throw_dir, on_fire)
			if on_fire:
				velocity += -throw_dir * FIRE_THROW_SPEED
			else:
				velocity = -throw_dir * THROW_SPEED
			if is_grounded:
				velocity[1] = 0
			
			rolling = false
			rolling_uphill = false
			if is_grounded:
				on_fire = false
			lose_dung()
			
			stop_aiming.call()
		elif Input.is_action_just_pressed("jump") and not has_dung and is_grounded:
			jumped = false
			is_grounded = false
			
			velocity = SOMERSAULT_VEC
			velocity[0] *= facing_dir
			
			stop_aiming.call()
		elif Input.is_action_just_released("aim"):
			stop_aiming.call()
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
	
	if not rolling:
		if is_grounded: # Facing dir
			if dir[0] > 0: 
				facing_dir = 1
			elif dir[0] < 0:
				facing_dir = -1
		
		var speed_dict = SPEED
		if slope_dir * dir[0] > 0:
			speed_dict = UP_SLOPE_SPEED
		elif slope_dir * dir[0] < 0:
			speed_dict = DOWN_SLOPE_SPEED
		
		var speed = speed_dict[has_dung]
		var accel = (ACCELERATIONS if dir.dot(velocity) > 0 else DECELERATIONS)[has_dung] if is_grounded else AIR_ACCELERATION
		velocity[0] = lerp(velocity[0], dir[0] * speed, accel)
	else:
		var speed = ROLLING_SPEED
		if slope_dir * dir[0] > 0:
			speed = UP_SLOPE_ROLLING_SPEED
		elif slope_dir * dir[0] < 0:
			speed = DOWN_SLOPE_ROLLING_SPEED
		velocity[0] = speed * rolling_dir
	
	# Vertical movement
	var gravity = ROLLING_GRAVITY if rolling else GRAVITY
	var terminal_speed = FIRE_TERMINAL_SPEED if on_fire else NORMAL_TERMINAL_SPEED
	velocity[1] = lerp(velocity[1], terminal_speed, gravity)
	
	if Input.is_action_just_pressed("jump") and is_grounded:
		if not has_dung:
			jumped = true
			velocity[1] += JUMP_SPEED
			velocity[0] = clamp(velocity[0], -MAX_HORIZONTAL_JUMP_SPEED, MAX_HORIZONTAL_JUMP_SPEED)
		else: # TODO Add can't jump effect
			pass
	
	# Fire hit logic
	if get_slide_collision_count() > 0 and on_fire:
		var normal = get_slide_collision(0).get_normal()
		
		var get_fire_hit = func(beetle_mod, dung_mod_idx):
			jumped = true
			on_fire = false
			rolling = false
			rolling_uphill = false
			
			velocity = FIRE_HIT_VEC
			velocity[0] *= beetle_mod 
			print(velocity)
			
			if has_dung:
				var throw_dir = velocity
				throw_dir[dung_mod_idx] *= -1
				dung.throw(throw_dir.normalized())
				lose_dung()
			
			var collider = get_slide_collision(0).get_collider()
			if collider.has_method("destroy"):
				collider.destroy()
		
		
		if abs(normal[0] - 0) < TOLERANCE and not rolling or not has_dung: # Floor hit
			jumped = true
			on_fire = false
			rolling = false
			rolling_uphill = false
			
			velocity = FIRE_HIT_VEC
			velocity[0] *= facing_dir 
			print(velocity)
			
			if has_dung:
				var throw_dir = velocity
				throw_dir[0] *= -1
				dung.throw(throw_dir.normalized())
				lose_dung()
			
			var collider = get_slide_collision(0).get_collider()
			if collider.has_method("destroy"):
				collider.destroy()
		elif abs(normal[1] - 0) < TOLERANCE: # Wall hit
			jumped = true
			on_fire = false
			rolling = false
			rolling_uphill = false
			
			velocity = FIRE_HIT_VEC
			velocity[0] *= -normal[0] 
			print(velocity)
			
			if has_dung:
				var throw_dir = velocity
				throw_dir[1] *= -1
				dung.throw(throw_dir.normalized())
				lose_dung()
			
			var collider = get_slide_collision(0).get_collider()
			if collider.has_method("destroy"):
				collider.destroy()
		elif normal[1] < 1 and not rolling: # Hill hit
			rolling = true
			facing_dir = -slope_dir
			rolling_dir = facing_dir
	
	# Roll jump logic
	if rolling and rolling_dir * slope_dir > 0:
		if abs(feet_raycast_distances[0][1] - feet_raycast_distances[1][1]) > RAYCAST_DIF_FOR_ROLLING_JUMP:
			rolling_uphill = true
		if rolling_uphill and abs(feet_raycast_distances[0][1] - feet_raycast_distances[1][1]) < RAYCAST_DIF_FOR_ROLLING_JUMP:
			rolling_uphill = false
			velocity[1] = ROLLING_JUMP_SPEED
			jumped = true
	
	var was_grounded = is_grounded
	move_and_slide()
	if not skip_floor_correction:
		is_grounded = is_on_floor()
	if is_grounded:
		has_pray_pulled = false
	
	# Floor correction
	if was_grounded and not is_on_floor() and not jumped and not skip_floor_correction:
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
	
	if skip_floor_correction:
		skip_floor_correction = false


func _animation_process(delta: float) -> void:
	sprite.flip_h = facing_dir < 0
	fire.visible = on_fire


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
	sprite.frame = 0
	has_dung = false


func get_dung():
	sprite.frame = 1
	has_dung = true


func adjust(adjustment_vector):
	skip_floor_correction = true
	if heavy_falling_height != null:
		heavy_falling_height += adjustment_vector[1]
