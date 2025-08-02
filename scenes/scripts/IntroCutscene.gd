extends Node2D
class_name Cutscene


@export var next_scene_path: String
@export var play_menu: bool = true


var current_anim = 0


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var skip: Node2D = $Skip


func _ready() -> void:
	if play_menu:
		SoundController.play_music("Cutscene")
	animation_player.play(str(current_anim))
	var sound = get_node_or_null("Sound/" + str(current_anim))
	if sound != null:
		sound.play()


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		var sound = get_node_or_null("Sound/" + str(current_anim))
		if sound != null:
			sound.stop()
		
		current_anim += 1
		if animation_player.has_animation(str(current_anim)):
			animation_player.play(str(current_anim))
			get_node("Sound/" + str(current_anim)).play()
		else:
			var sound_to_play = get_node_or_null("Sound/" + str(current_anim))
			if sound_to_play != null:
				sound_to_play.stop()
			SceneManager.goto_scene(next_scene_path)


func _process(delta: float) -> void:
	skip.visible = not animation_player.is_playing()


func shake():
	GlobalCamera.add_trauma()
