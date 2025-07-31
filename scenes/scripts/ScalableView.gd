extends Node2D
class_name ScalableView


const ZOOM_LERP_WEIGHT = 0.03


var aim_zoom = Vector2(1.0, 1.0)


func _process(delta: float) -> void:
	scale = lerp(scale, aim_zoom, ZOOM_LERP_WEIGHT)


func snap_zoom():
	scale = aim_zoom
