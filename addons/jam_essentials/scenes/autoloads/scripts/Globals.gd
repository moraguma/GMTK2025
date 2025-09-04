extends Node


const MASTER_BUS = 0
const MUSIC_BUS = 1
const SFX_BUS = 2
const BUS_TO_STRING = {
	MASTER_BUS: "Master",
	MUSIC_BUS: "Music",
	SFX_BUS: "SFX"
}


var has_recipe = false
var checked_pins = []
var loop_count = 0
var best_time = 60.0
var last_times = {
	"Reach Olympus": 60.0,
	"Escape Hades": 90.0
}

var best_times = {
	"Reach Olympus": 60.0,
	"Escape Hades": 90.0
}


## If not empty, loads this default save once the game starts
@export var default_save: String = "save"

## Saves flags temporarily. Will not be maintained between sessions
var temp_flags = {}


func _ready() -> void:
	if default_save != "":
		Save.load_game(default_save)
	Save.load_options()



## If the given check is true, pushes a warning message and returns true.
## Otherwise, returns false
func check_and_error(check: bool, message: String):
	if check:
		push_error(message)
		return true
	return false


func check_pin(pin_name):
	if not pin_name in checked_pins:
		checked_pins.append(pin_name)


## Creates a callable for method func_name in object bound to the binds array
func create_callable(object: Object, func_name: String, binds: Array) -> Callable:
	var callable: Callable = Callable(object, func_name)
	if len(binds) > 0:
		callable = callable.bindv(binds)
	return callable


## Given a control node connects the related sounds to hovering and focusing
func connect_focus_sounds(c: Control) -> void:
	c.mouse_entered.connect(SoundController.play_sfx.bind("Hover"))
	c.focus_entered.connect(SoundController.play_sfx.bind("Hover"))


## Time dependent lerp
func tlerp(a, b, weight: float, delta: float):
	return lerp(a, b, exp(-weight * delta))


func set_temp_flag(n: String) -> void:
	temp_flags[n] = true


func get_temp_flag(n: String) -> bool:
	if not n in temp_flags:
		return false
	return temp_flags[n]


func reset_temp_flags() -> void:
	temp_flags = {}
