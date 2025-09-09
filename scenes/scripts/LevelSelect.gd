extends Node2D
class_name LevelSelect


const LERP_WEIGHT = 0.2
const ARROW_AMPLITUDE = 32.0
const ARROW_FREQ = 0.5


@export var deselected_vector: Vector2 = Vector2(-256, 0)
@export var deselected_modulate: Color


var selected = false
var time_elapsed = 0.0


@onready var base: CanvasGroup = $Base
@onready var arrow: Sprite2D = $Arrow
@onready var base_base_pos: Vector2 = base.position


func _ready() -> void:
	base.position = base_base_pos + deselected_vector
	base.self_modulate = deselected_modulate


func _process(delta: float) -> void:
	time_elapsed += delta
	arrow.offset[1] = ARROW_AMPLITUDE * cos(2 * PI * time_elapsed * ARROW_FREQ)
	
	base.position = lerp(base.position, base_base_pos + (Vector2(0, 0) if selected else deselected_vector), LERP_WEIGHT)
	base.self_modulate = lerp(base.self_modulate, Color("#ffffff") if selected else deselected_modulate, LERP_WEIGHT)


func select():
	selected = true
	arrow.hide()


func deselect():
	selected = false
	arrow.show()
