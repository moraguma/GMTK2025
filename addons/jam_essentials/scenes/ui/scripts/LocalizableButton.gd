@tool
extends Button
class_name LocalizableButton


@export var localization_code: String = "":
	set(val):
		localization_code = val
		localize()
@export var play_sound: bool = false


func _ready() -> void:
	Globals.connect_focus_sounds(self)
	pressed.connect(SoundController.play_sfx.bind("Play" if play_sound else "Click"))
	
	add_to_group("localizable")
	
	localize()


func localize() -> void:
	text = tr(localization_code)
