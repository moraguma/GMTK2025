@tool
extends HBoxContainer
class_name InputTextDisplay


@export var action: String:
	set(val):
		action = val
		if Engine.is_editor_hint():
			$InputDisplay.action = val
			$LocalizableLabel.localization_code = custom_action_name if custom_action_name != "" else val
@export var custom_action_name: String:
	set(val):
		custom_action_name = val
		if Engine.is_editor_hint():
			$LocalizableLabel.localization_code = val if val != "" else action


func _ready() -> void:
	$InputDisplay.action = action
	$InputDisplay.update_display(InputHelper.device, InputHelper.device_index)
	$LocalizableLabel.localization_code = custom_action_name if custom_action_name != "" else action
