extends Area2D
class_name MapArea


@export var pin_name: String


func _ready() -> void:
	body_entered.connect(entered)


func entered(body):
	body.check_pin(pin_name)
