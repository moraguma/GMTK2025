extends StaticBody2D
class_name Destructible


@export var sound: String


func destroy():
	queue_free()
	
	SoundController.play_sfx(sound)
