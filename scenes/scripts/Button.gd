extends TextureButton


func _ready() -> void:
	mouse_entered.connect(SoundController.play_sfx.bind("Hover"))
