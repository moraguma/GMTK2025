extends CharacterBody2D
class_name Dung


const THROW_SPEED = 1500.0
const FIRE_SPEED = 1300.0
const NORMAL_TERMINAL_SPEED = 3400.0
const ROLL_TRANSMISSION = 0.03
const THROW_ADJUST_AMOUNT = 50.0

const PICK_TIME = 0.5

const AIR_RESISTANCE = 0.012
const GRAVITY = 0.01


var active = false
var landed = true
var aiming = false
var player: Beetle = null
var on_fire = false
var dung_sprite_overrided = false
var fire_recoil = false


@onready var pick_timer: Timer = $PickTimer
@onready var collection_area: Area2D = $CollectionArea
@onready var sprite: ShakingSprite = $Sprite
@onready var fire: AnimatedSprite2D = $FirePivot/Fire
@onready var fire_pivot: Node2D = $FirePivot
@onready var goop_pivot: Node2D = $GoopPivot
@onready var dung_particles: CPUParticles2D = $DungParticles
@onready var fire_recoil_timer: Timer = $FireRecoilTimer


func _ready() -> void:
	fire_recoil_timer.timeout.connect(set.bind("fire_recoil", false))
	
	fire.play("default")


func _physics_process(delta: float) -> void:
	_movement_process(delta)
	_animation_process(delta)


func _movement_process(delta: float) -> void:
	if not active or landed or aiming: 
		return
	
	if not fire_recoil:
		# Air resistance
		velocity[0] = lerp(velocity[0], 0.0, AIR_RESISTANCE)
		
		# Gravity
		velocity[1] = lerp(velocity[1], NORMAL_TERMINAL_SPEED, GRAVITY)
	
	if move_and_slide():
		var collision: KinematicCollision2D = get_last_slide_collision()
		if on_fire and collision.get_collider().has_method("destroy"):
			collision.get_collider().destroy()
			fire_recoil = false
			fire_recoil_timer.stop()
			
			var old_dir = velocity[0] / abs(velocity[0])
			velocity = Beetle.FIRE_HIT_VEC
			if abs(collision.get_normal()[1]) > Beetle.TOLERANCE: # Vertical
				velocity[0] *= -old_dir
			else: # Horizontal
				velocity[1] *= -1
				if collision.get_normal()[0] > 0:
					velocity[0] *= -1
		else:
			SoundController.play_sfx("DungImpact")
			player.world_camera.add_trauma(GlobalCamera.SMALL_SHAKE)
			
			goop_pivot.rotation = Vector2(0, -1).angle_to(-get_slide_collision(0).get_normal())
			
			landed = true
		on_fire = false


func _animation_process(delta: float) -> void:
	fire_pivot.rotation = Vector2(0, 1).angle_to(velocity)
	
	dung_particles.emitting = not landed and active
	goop_pivot.visible = landed and active
	
	fire.visible = on_fire
	
	if not landed:
		sprite.rotation += velocity[0] * ROLL_TRANSMISSION * delta
	
	if dung_sprite_overrided:
		dung_sprite_overrided = false
	else:
		sprite.position = Vector2(0, 0)


## Throws dung, starting from player, in given direction
func throw(dir, catch_fire=false):
	activate()
	pick_timer.start(PICK_TIME)
	on_fire = catch_fire
	if catch_fire:
		fire_recoil = true
		fire_recoil_timer.start(Beetle.FIRE_RECOIL_TIME)
	
	position = player.position + dir * THROW_ADJUST_AMOUNT
	velocity = dir * (Beetle.FIRE_THROW_SPEED if on_fire else THROW_SPEED)


## Called when player enters collection area. deactivates and gives player dung
func collect(body):
	if not pick_timer.is_stopped():
		return
	
	body.get_dung(true)
	deactivate()


func activate():
	active = true
	landed = false
	
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)
	collection_area.set_collision_mask_value(2, true)
	sprite.show()


func deactivate():
	active = false
	
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)
	collection_area.set_collision_mask_value(2, false)
	sprite.hide()


func destroy_leaf(body: Node2D) -> void:
	player.world_camera.add_trauma(GlobalCamera.SMALL_SHAKE)
	body.destroy()


func override_sprite_pos(pos: Vector2) -> void:
	dung_sprite_overrided = true
	sprite.position = pos
