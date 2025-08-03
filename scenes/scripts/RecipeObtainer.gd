extends Area2D


func _ready() -> void:
	body_entered.connect(change)


func change(body):
	body.get_recipe()
