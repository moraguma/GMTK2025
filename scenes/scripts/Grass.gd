@tool
extends Polygon2D


const STRAND_HEIGHT = 0.8
const STRAND_RAND = 0.4
const CONNECTION_HEIGHT = 0.2
const CONNECTION_RAND = 0.2
const SPACING_RAND = 4.0


const SKEW_CENTER = -PI / 12
const SKEW_AMPLITUDE = PI / 24
const SKEW_FREQUENCY = 0.5


@export var auto: bool = false
@export_range(8.0, 1960.0) var size: float = 32.0:
	set(val):
		size = val
		bake()
@export_range(8.0, 256.0) var height: float = 8.0:
	set(val):
		height = val
		bake()
@export_range(16.0, 64.0) var spacing: float = 16.0:
	set(val):
		spacing = val
		bake()


var time = 0.0


func _process(delta: float) -> void:
	time += delta
	
	skew = SKEW_CENTER + SKEW_AMPLITUDE * cos(2 * PI * SKEW_FREQUENCY * time)


func bake():
	if not Engine.is_editor_hint() or not auto:
		return
	
	var pos = spacing + randf() * SPACING_RAND
	var new_polygon = [Vector2(0.0, 0.0), Vector2(pos, -height * STRAND_HEIGHT + -height * randf() * STRAND_RAND)]
	pos += spacing + randf() * SPACING_RAND
	
	while pos < size:
		new_polygon.append(Vector2(pos, -height * CONNECTION_HEIGHT + -height * randf() * CONNECTION_RAND))
		pos += spacing + randf() * SPACING_RAND
		new_polygon.append(Vector2(pos, -height * STRAND_HEIGHT + -height * randf() * STRAND_RAND))
		pos += spacing + randf() * SPACING_RAND
	
	new_polygon.append(Vector2(pos, 0.0))
	polygon = new_polygon
