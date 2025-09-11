extends BaseButton


func _ready() -> void:
	mouse_entered.connect(SoundController.play_sfx.bind("Hover"))


func _pressed() -> void:
	SteamInterface.go_to_store(3971000, "https://store.steampowered.com/app/3971000/Sisyphus_Is_a_Bug/")
	release_focus()
