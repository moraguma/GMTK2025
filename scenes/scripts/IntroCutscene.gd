extends Node2D
class_name Cutscene


@export var next_scene_path: String


var current_anim = 0


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var skip: Node2D = $Skip


func _ready() -> void:
	animation_player.play(str(current_anim))


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		current_anim += 1
		if animation_player.has_animation(str(current_anim)):
			animation_player.play(str(current_anim))
		else:
			SceneManager.goto_scene(next_scene_path)


func _process(delta: float) -> void:
	skip.visible = not animation_player.is_playing()


func shake():
	GlobalCamera.add_trauma()
