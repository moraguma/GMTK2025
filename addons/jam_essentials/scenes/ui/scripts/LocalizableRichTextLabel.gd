@tool
extends RichTextLabel
class_name LocalizableRichTextLabel


@export var localization_code: String = "":
	set(val):
		localization_code = val
		localize()


func _ready() -> void:
	add_to_group("localizable")
	
	localize()


func localize() -> void:
	text = tr(localization_code)
