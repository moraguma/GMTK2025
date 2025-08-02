extends Area2D


@export var area = "tartarus"


func _ready() -> void:
	body_entered.connect(change)


func change(body):
	body.change_area(area)
