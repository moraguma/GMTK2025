extends CharacterBody2D
class_name Beetle


const DUNG_SCENE = preload("res://scenes/Dung.tscn")

const CAMERA_LERP = 1.0
const CAMERA_VEL_TRANSMISSION = 0.3
const TIME_FOR_FIRE_LOOP_SOUND = 0.2

const DUNG_ROLL_ANIM_TRANSMISSION = 0.012
const RAYCAST_DIF_FOR_ROLLING_JUMP = 64
const NORMAL_TERMINAL_SPEED = 3400.0
const FIRE_TERMINAL_SPEED = 5500.0
const JUMP_SPEED = -1050.0
const ROLLING_JUMP_SPEED = -1800.0
const SOMERSAULT_VEC = Vector2(-200, -1400)
const FIRE_HIT_VEC = Vector2(-300, -1400)
const THROW_SPEED = 900.0
const FIRE_THROW_SPEED = 700.0
const CATCH_SPEED = 1500.0
const MAX_HORIZONTAL_JUMP_SPEED = 300.0
const ROLLING_SPEED = 1200.0
const UP_SLOPE_ROLLING_SPEED = 1750.0
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
const ROLLING_GRAVITY = 0.008
const AIR_ACCELERATION = 0.0
const ACCELERATIONS = {
	false: 0.08,
	true: 0.04
}
const DECELERATIONS = {
	false: 0.15,
	true: 0.04
}


const TIME_FOR_PRAY_PULL = 2.0
const TIME_FOR_RESET = 1.0

const HEIGHT_FOR_FIRE = 720.0
const PRAY_PULL_MAX_DIST = 1250.0
const MAX_GROUNDED_THROW_ANGLE = PI / 3
const TOLERANCE = 0.001
const ANIM_TOLERANCE = 30.0
const PALETTE_LERP_WEIGHT = 0.1

@export var tartarus_bg_from: Color = Color("#efeae1")
@export var tartarus_bg_to: Color = Color("#ffffff")
@export var tartarus_detail_from: Color = Color("#bb6270")
@export var tartarus_detail_to: Color = Color("#6e2f3e")
@export var tartarus_ground_from: Color = Color("#c07c71")
@export var tartarus_ground_to: Color = Color("#662630")

@export var earth_bg_from: Color = Color("#ecefe1")
@export var earth_bg_to: Color = Color("#ffffff")
@export var earth_detail_from: Color = Color("#ca9072")
@export var earth_detail_to: Color = Color("#57342d")
@export var earth_ground_from: Color = Color("#5c9671")
@export var earth_ground_to: Color = Color("#41543b")

@export var olympus_bg_from: Color = Color("#fffddf")
@export var olympus_bg_to: Color = Color("#ffffff")
@export var olympus_detail_from: Color = Color("#c9b262")
@export var olympus_detail_to: Color = Color("#817d42")
@export var olympus_ground_from: Color = Color("#f1ddb2")
@export var olympus_ground_to: Color = Color("#b16d51")

var palette_data = {
	"tartarus": [
		tartarus_bg_from,
		tartarus_bg_to,
		tartarus_detail_from,
		tartarus_detail_to,
		tartarus_ground_from,
		tartarus_ground_to
	],
	"earth": [
		earth_bg_from,
		earth_bg_to,
		earth_detail_from,
		earth_detail_to,
		earth_ground_from,
		earth_ground_to
	],
	"olympus": [
		olympus_bg_from,
		olympus_bg_to,
		olympus_detail_from,
		olympus_detail_to,
		olympus_ground_from,
		olympus_ground_to
	],
}
var palette_pos_to_shader = [
		"bg_from",
		"bg_to",
		"detail_from",
		"detail_to",
		"ground_from",
		"ground_to"
]
var palette = [
	tartarus_bg_from,
	tartarus_bg_to,
	tartarus_detail_from,
	tartarus_detail_to,
	tartarus_ground_from,
	tartarus_ground_to
]

var palette_name = "tartarus"
var palette_pos = 0

var time_fire_started = 0.0
var dung: Dung
var world_camera: WorldCamera
var world_loader: WorldLoader
var has_dung = true
var on_fire = false
var rolling = false
var rolling_uphill = false
var rolling_dir = 1
var aiming = false
var pulling = false
var facing_dir = 1
var heavy_falling_height = null
var time_pulling_started = null
var can_pray_pull = false
var has_pray_pulled = false
var skip_floor_correction = false
var animation_before_pray = "idle"
var reset_progress = 0.0
var can_reset = true

var is_grounded = true
var camera_aim = Vector2(0, 0)

@onready var fire: AnimatedSprite2D = $SpritePivot/Fire
@onready var sprite: ShakingSprite = $SpritePivot/Sprite
@onready var sprite_pivot: Squisher = $SpritePivot
@onready var animation_player: TransitionAnimationPlayer = $AnimationPlayer
@onready var left_feet_cast: RayCast2D = $LeftFeetCast
@onready var right_feet_cast: RayCast2D = $RightFeetCast
@onready var dung_detector: RayCast2D = $DungDetector
@onready var arrow_pivot: Node2D = $ArrowPivot
@onready var ground_detectors: Array[RayCast2D] = [$GroundDetectorL, $GroundDetectorR]
@onready var dung_holder: Node2D = $SpritePivot/DungHolder
@onready var dung_sprite: Sprite2D = $SpritePivot/DungHolder/Dung
@onready var anim_floor_detector: RayCast2D = $AnimFloorDetector
@onready var sprite_base_pos: Vector2 = sprite_pivot.position
@onready var halo: Sprite2D = $SpritePivot/Halo
@onready var dung_particles: CPUParticles2D = $SpritePivot/DungParticles
@onready var dust_particles: CPUParticles2D = $SpritePivot/DustParticles
@onready var reset_container: Node2D = $Reset
@onready var reset_progress_bar: TextureProgressBar = $Reset/ResetProgressBar
@onready var camera_follow: Node2D = $CameraFollow
@onready var fire_loop_audio: AudioStreamPlayer = $FireLoop
@onready var aim_loop_audio: AudioStreamPlayer = $AimLoop
@onready var push_loop_audio: AudioStreamPlayer = $PushLoop
@onready var roll_loop_audio: AudioStreamPlayer = $RollLoop


func _ready() -> void:
	fire_loop_audio.play()
	aim_loop_audio.play()
	push_loop_audio.play()
	roll_loop_audio.play()
	
	fire.play("default")
	
	dung = DUNG_SCENE.instantiate()
	dung.player = self
	get_parent().add_child.call_deferred(dung)
	dung.deactivate.call_deferred()


func _physics_process(delta: float) -> void:
	_movement_process(delta)
	_animation_process(delta)
	
	if Input.is_action_pressed("reset") and can_reset:
		reset_progress += delta
		reset_container.show()
		reset_progress_bar.value = reset_progress / TIME_FOR_RESET
		
		if reset_progress >= TIME_FOR_RESET:
			can_reset = false
			world_loader.queue_reset()
	else:
		reset_progress = 0.0
		reset_container.hide()


func _process(delta: float) -> void:
	camera_aim = Vector2(velocity[0] * CAMERA_VEL_TRANSMISSION, 0)
	if not has_dung and (dung.position - position).length() < PRAY_PULL_MAX_DIST:
		camera_aim = (dung.position - position) / 2.0
	
	camera_follow.position = lerp(camera_follow.position, camera_aim, CAMERA_LERP)
	
	_palette_process(delta)
	_sound_process(delta)


func _movement_process(delta: float) -> void:
	# Fire logic
	if has_dung and not is_grounded:
		if heavy_falling_height == null or position[1] < heavy_falling_height:
			heavy_falling_height = position[1]
		
		if position[1] - heavy_falling_height >= HEIGHT_FOR_FIRE:
			if not on_fire:
				time_fire_started = Time.get_ticks_msec()
				SoundController.play_sfx("Fire")
				on_fire = true
	else:
		heavy_falling_height = null
	
	# Throw logic
	if Input.is_action_just_pressed("aim") and not aiming and not rolling: # Start aim
		SoundController.set_music_paused(true)
		SoundController.play_sfx("Aim")
		
		animation_before_pray = animation_player.current_animation
		
		if has_dung:
			animation_player.play("aim" if is_grounded else "aim_air")
		else:
			animation_player.play("pray")
		
		world_loader.game_timer.paused = true
		aiming = true
		dung.aiming = true
		
		if has_dung:
			arrow_pivot.show()
		
		can_pray_pull = false
		if not has_dung and dung.landed and (is_grounded or not has_pray_pulled) and (dung.position - position).length() < PRAY_PULL_MAX_DIST:
			can_pray_pull = true
		#can_pray_pull = false
		#if not has_dung and dung.landed and (is_grounded or not has_pray_pulled) and (dung.position - position).length() < PRAY_PULL_MAX_DIST:
			#dung_detector.target_position = dung.position - position
			#dung_detector.force_raycast_update()
			#if not dung_detector.is_colliding():
				#can_pray_pull = true
	
	var stop_aiming = func():
		aiming = false
		dung.aiming = false
		arrow_pivot.hide()
		pulling = false
		world_loader.game_timer.paused = false
		
		SoundController.set_music_paused(false)
		SoundController.play_sfx("StopAim")
	
	var jumped = false
	if aiming and not has_dung: # Pray pull
		if Input.is_action_just_pressed("throw"):
			if can_pray_pull:
				SoundController.play_sfx("PrayPull")
				pulling = true
			else:
				SoundController.play_sfx("NoJump")
				sprite_pivot.squish()
			time_pulling_started = Time.get_ticks_msec()
		elif Input.is_action_just_released("throw"):
			SoundController.stop_sfx("PrayPull")
			pulling = false
		
		if pulling:
			var time_elapsed = (Time.get_ticks_msec() - time_pulling_started) / 1000.0
			var progress = min(time_elapsed / TIME_FOR_PRAY_PULL, 1.0)
			sprite.trauma = progress
			if can_pray_pull:
				dung.sprite.trauma = progress
				
				if time_elapsed >= TIME_FOR_PRAY_PULL:
					SoundController.play_sfx("DungImpact")
					
					dung.deactivate()
					get_dung()
					stop_aiming.call()
					
					var pray_dir = (position - dung.position).normalized()
					velocity = pray_dir * CATCH_SPEED
					
					facing_dir = 1 if pray_dir[0] < 0 else -1
					
					if is_grounded:
						velocity[1] = 0
						animation_player.play("ball_idle")
					else:
						has_pray_pulled = true
						animation_player.play("ball_fall")
	
	if aiming: # Aim actions
		var throw_dir = (world_loader.get_global_mouse_position() - (global_position - world_camera.get_screen_center_position())).normalized()
		if is_grounded:
			var angle = clamp(Vector2(0, -1).angle_to(throw_dir), -MAX_GROUNDED_THROW_ANGLE, MAX_GROUNDED_THROW_ANGLE)
			throw_dir = Vector2(0, -1).rotated(angle)
		
		arrow_pivot.rotation = Vector2(0, -1).angle_to(throw_dir)
		
		if Input.is_action_just_pressed("throw") and has_dung:
			SoundController.play_sfx("Throw")
			
			if not is_grounded:
				facing_dir = throw_dir[0] / abs(throw_dir[0])
			
			dung.throw(throw_dir, on_fire)
			if on_fire:
				velocity += -throw_dir * FIRE_THROW_SPEED
			else:
				velocity = -throw_dir * THROW_SPEED
			
			if is_grounded:
				animation_player.play("throw")
				velocity[1] = 0
			else:
				animation_player.play("throw_air")
			
			rolling = false
			rolling_uphill = false
			if is_grounded:
				on_fire = false
			lose_dung()
			
			stop_aiming.call()
		elif Input.is_action_just_pressed("jump") and not has_dung and is_grounded:
			SoundController.play_sfx("Jump")
			animation_player.play("jump")
			
			jumped = true
			is_grounded = false
			
			velocity = SOMERSAULT_VEC
			velocity[0] *= facing_dir
			
			stop_aiming.call()
		elif Input.is_action_just_released("aim"):
			animation_player.play(animation_before_pray)
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
		if slope_dir * rolling_dir > 0:
			speed = UP_SLOPE_ROLLING_SPEED
		elif slope_dir * rolling_dir < 0:
			speed = DOWN_SLOPE_ROLLING_SPEED
		velocity[0] = speed * rolling_dir
	
	# Vertical movement
	var gravity = ROLLING_GRAVITY if rolling else GRAVITY
	var terminal_speed = FIRE_TERMINAL_SPEED if on_fire else NORMAL_TERMINAL_SPEED
	velocity[1] = lerp(velocity[1], terminal_speed, gravity)
	
	var can_jump = false
	for ground_detector in ground_detectors:
		if ground_detector.is_colliding():
			can_jump = true
			break
	
	if Input.is_action_just_pressed("jump") and can_jump and not jumped:
		if not has_dung:
			SoundController.play_sfx("Jump")
			animation_player.play("jump")
			
			jumped = true
			velocity[1] = JUMP_SPEED
			velocity[0] = clamp(velocity[0], -MAX_HORIZONTAL_JUMP_SPEED, MAX_HORIZONTAL_JUMP_SPEED)
		else: 
			SoundController.play_sfx("NoJump")
			sprite_pivot.squish()
	
	# Fire hit logic
	if get_slide_collision_count() > 0 and on_fire:
		var normal = get_slide_collision(0).get_normal()
		
		if abs(normal[0]) < TOLERANCE and normal[1] < 0 and not rolling or not has_dung: # Floor hit
			SoundController.play_sfx("Bounce")
			
			animation_player.play("fall")
			
			jumped = true
			on_fire = false
			rolling = false
			rolling_uphill = false
			
			velocity = FIRE_HIT_VEC
			velocity[0] *= facing_dir 
			
			if has_dung:
				var throw_dir = velocity
				throw_dir[0] *= -1
				dung.throw(throw_dir.normalized())
				lose_dung()
			
			var collider = get_slide_collision(0).get_collider()
			if collider.has_method("destroy"):
				collider.destroy()
		elif abs(normal[1] - 0) < TOLERANCE: # Wall hit
			SoundController.play_sfx("Bounce")
			
			animation_player.play("fall")
			
			jumped = true
			on_fire = false
			rolling = false
			rolling_uphill = false
			
			velocity = FIRE_HIT_VEC
			velocity[0] *= -normal[0] 
			
			if has_dung:
				var throw_dir = velocity
				throw_dir[1] *= -1
				dung.throw(throw_dir.normalized())
				dung.position[0] += throw_dir[0] / abs(throw_dir[0]) * 50
				lose_dung()
			
			var collider = get_slide_collision(0).get_collider()
			if collider.has_method("destroy"):
				collider.destroy()
		elif normal[1] < 1 and not rolling: # Hill hit
			animation_player.play("roll")
			
			rolling = true
			facing_dir = -slope_dir
			rolling_dir = facing_dir
	
	# Roll jump logic
	if rolling and rolling_dir * slope_dir > 0:
		if abs(feet_raycast_distances[0][1] - feet_raycast_distances[1][1]) > RAYCAST_DIF_FOR_ROLLING_JUMP and is_grounded:
			rolling_uphill = true
		if rolling_uphill and abs(feet_raycast_distances[0][1] - feet_raycast_distances[1][1]) < RAYCAST_DIF_FOR_ROLLING_JUMP:
			SoundController.play_sfx("Jump")
			animation_player.play("roll_fall")
			
			rolling_uphill = false
			velocity[1] = ROLLING_JUMP_SPEED
			jumped = true
	
	var was_grounded = is_grounded
	move_and_slide()
	if not skip_floor_correction:
		is_grounded = is_on_floor()
	if can_jump:
		has_pray_pulled = false
	
	if not was_grounded and is_grounded:
		SoundController.play_sfx("Land")
		if rolling:
			animation_player.play("roll")
		elif has_dung:
			animation_player.play("ball_idle")
		else:
			animation_player.play("land")
	
	# Floor correction
	if was_grounded and not is_on_floor() and not jumped and not skip_floor_correction:
		var movement_options = get_feet_raycast_movements()
		var effective_movement_options = []
		for movement_option in movement_options:
			if movement_option[1] > 0:
				effective_movement_options.append(movement_option)
		
		if len(effective_movement_options) > 0:
			var min_movement = effective_movement_options[0]
			var min_movement_length = min_movement.length()
			for i in range(1, len(effective_movement_options)):
				var movement_length = effective_movement_options[i].length()
				if movement_length < min_movement_length:
					min_movement = effective_movement_options[i]
					min_movement_length = movement_length
			
			if min_movement[1] > 0:
				position += min_movement
				is_grounded = true
	
	if skip_floor_correction:
		skip_floor_correction = false


func _animation_process(delta: float) -> void:
	if rolling:
		fire.rotation = -PI / 2 * rolling_dir
	else:
		fire.rotation = 0
	dust_particles.emitting = (facing_dir * velocity[0] < 0 and is_grounded and abs(velocity[0]) > ANIM_TOLERANCE) or animation_player.current_animation == "land"
	sprite.flip_h = facing_dir < 0
	halo.offset = Vector2(-2 * halo.position[0], 0) if sprite.flip_h else Vector2(0, 0)
	halo.visible = not has_pray_pulled
	fire.visible = on_fire
	
	anim_floor_detector.force_raycast_update()
	var vec_to_ground = anim_floor_detector.get_collision_point() - anim_floor_detector.global_position
	if is_grounded and not aiming:
		if anim_floor_detector.is_colliding():
			sprite_pivot.position = sprite_base_pos + vec_to_ground
		
		var floor_movements = get_feet_raycast_movements()
		var angle_movements
		if floor_movements[0][1] > 0.5:
			angle_movements = [floor_movements[0][1], vec_to_ground[1]]
		else:
			angle_movements = [vec_to_ground[1], floor_movements[1][1] if floor_movements[1][1] >= 0.0 else 40.0]
		var ang = atan((angle_movements[1] - angle_movements[0]) / 40.0)
		sprite_pivot.rotation = ang
	else:
		sprite_pivot.rotation = 0
	
	
	dung_holder.scale[0] = -1 if facing_dir < 0 else 1
	dung_particles.position[0] = abs(dung_particles.position[0]) * dung_holder.scale[0]
	dung_sprite.rotation += facing_dir * velocity[0] * DUNG_ROLL_ANIM_TRANSMISSION * delta
	
	if is_grounded:
		if abs(velocity[0]) < ANIM_TOLERANCE:
			if has_dung:
				animation_player.transition_anim("ball_idle")
			else:
				animation_player.transition_anim("idle")
		else:
			if has_dung:
				animation_player.transition_anim("ball_walk")
			else:
				animation_player.transition_anim("walk")
	else:
		animation_player.transition_anim("ball_fall" if has_dung else "fall")
	
	dung_particles.emitting = abs(velocity[0]) > ANIM_TOLERANCE and is_grounded and has_dung
	dung_holder.visible = animation_player.current_animation in ["roll", "ball_walk"]


func _palette_process(delta: float) -> void:
	palette[palette_pos] = lerp(palette[palette_pos], palette_data[palette_name][palette_pos], PALETTE_LERP_WEIGHT)
	RenderingServer.global_shader_parameter_set(palette_pos_to_shader[palette_pos], palette[palette_pos])
	palette_pos += 1
	if palette_pos >= len(palette):
		palette_pos = 0


func _sound_process(delta: float) -> void:
	var current_time = Time.get_ticks_msec()
	fire_loop_audio.volume_db = -5.0 if on_fire and (current_time - time_fire_started) / 1000.0 > TIME_FOR_FIRE_LOOP_SOUND else -80
	aim_loop_audio.volume_db = 0.0 if aiming else -80.0
	push_loop_audio.volume_db = 0.0 if animation_player.current_animation == "ball_walk" else -80.0
	roll_loop_audio.volume_db = 0.0 if animation_player.current_animation == "roll" else -80.0
	
	push_loop_audio.pitch_scale = max(0.01, abs(velocity[0]) / SPEED[true])


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


func get_dung(play_sound=false):
	if play_sound:
		SoundController.play_sfx("GetDung")
	
	has_dung = true
	
	animation_player.play("ball_idle" if is_grounded else "ball_fall")


func adjust(adjustment_vector):
	skip_floor_correction = true
	if heavy_falling_height != null:
		heavy_falling_height += adjustment_vector[1]


func play_sfx(sfx_name):
	SoundController.play_sfx(sfx_name)


func change_area(area):
	palette_name = area


func finish():
	pass
