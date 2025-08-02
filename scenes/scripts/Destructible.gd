extends StaticBody2D
class_name Destructible


@export var sound: String
@onready var sprite: Sprite2D = $Sprite


var destroyed = false


func destroy():
	if destroyed:
		return
	destroyed = true
	
	$Hitbox.queue_free()
	$Particles.emitting = true
	sprite.hide()
	
	SoundController.play_sfx(sound)
