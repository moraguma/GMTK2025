extends Node


const MASTER_BUS = 0
const MUSIC_BUS = 1
const SFX_BUS = 2
const BUS_TO_STRING = {
	MASTER_BUS: "Master",
	MUSIC_BUS: "Music",
	SFX_BUS: "SFX"
}


var checked_pins = []


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
