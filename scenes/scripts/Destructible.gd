@tool
extends StaticBody2D
class_name Destructible


@export var sound: String
@export_range(0.0, PI/3.0) var waving_amp: float
@export var freq: float
@export_range(-PI/3.0, PI/3.0) var skew_base: float


@onready var sprite: Sprite2D = $Sprite
@onready var skewer: Node2D = $Skewer


var destroyed = false
var time_elapsed = 0


func _ready() -> void:
	if Globals.get_temp_flag(name):
		destroy(null, true)
	
	var player_destroy = get_node_or_null("PlayerDestroy")
	if player_destroy != null:
		player_destroy.body_entered.connect(destroy)


func _process(delta: float) -> void:
	time_elapsed += delta
	skewer.skew = skew_base + waving_amp * cos(2 * PI * freq * time_elapsed)


func destroy(body=null, no_sound=false):
	Globals.set_temp_flag(name)
	
	if destroyed:
		return
	destroyed = true
	
	$Hitbox.queue_free()
	$Particles.emitting = true
	skewer.hide()
	
	if not no_sound:
		SoundController.play_sfx(sound)
