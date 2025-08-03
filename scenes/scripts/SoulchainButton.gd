extends Button


func _ready() -> void:
	mouse_entered.connect(SoundController.play_sfx.bind("Hover"))


func _pressed() -> void:
	OS.shell_open("https://store.steampowered.com/app/3383610/Soulchain/")
