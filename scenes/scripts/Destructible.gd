extends StaticBody2D
class_name Destructible


@export var sound: String
@onready var sprite: Sprite2D = $Sprite


var destroyed = false


func _ready() -> void:
	var player_destroy = get_node_or_null("PlayerDestroy")
	if player_destroy != null:
		player_destroy.body_entered.connect(destroy)


func destroy(body=null):
	if destroyed:
		return
	destroyed = true
	
	$Hitbox.queue_free()
	$Particles.emitting = true
	sprite.hide()
	
	SoundController.play_sfx(sound)
