extends Area2D



func _ready() -> void:
	body_entered.connect(finish)


func finish(body: Node2D) -> void:
	body.finish()
