extends Node2D
class_name Cutscene


@export var next_scene_path: String


var current_anim = 0


@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
