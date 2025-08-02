extends Node2D
class_name Squisher


const LERP_WEIGHT = 0.1


func _process(delta: float) -> void:
	scale[1] = lerp(scale[1], 1.0, LERP_WEIGHT)


func squish():
	scale[1] = 1.2
