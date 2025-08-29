extends Node2D
class_name Menu


const WORLD_SCROLL_SPEED = 150
const Y_TO_RECENTER_WORLD = 1920
const DUNG_ROLL_ANIM_TRANSMISSION = 0.0095


@onready var world_bits: Node2D = $WorldBits
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var dung: Sprite2D = $Dung
@onready var main: Node2D = $Main
@onready var credits: Node2D = $Credits
@onready var options: Options = $Options


func _ready() -> void:
	$Main/Buttons/Play.grab_focus()
	
	Globals.loop_count = 0
	
	SoundController.play_music("Menu")
	animation_player.play("roll")
	
	GlobalCamera.follow_node(self)
	GlobalCamera.snap_to_aim()
	
	RenderingServer.global_shader_parameter_set("bg_from", Color("#fffddf"))
	await get_tree().process_frame
	RenderingServer.global_shader_parameter_set("bg_to", Color("#ffffff"))
	await get_tree().process_frame
	RenderingServer.global_shader_parameter_set("detail_from", Color("#c9b262"))
	await get_tree().process_frame
	RenderingServer.global_shader_parameter_set("detail_to", Color("#817d42"))
	await get_tree().process_frame
	RenderingServer.global_shader_parameter_set("ground_from", Color("#f1ddb2"))
	await get_tree().process_frame
	RenderingServer.global_shader_parameter_set("ground_to", Color("#b16d51"))
	await get_tree().process_frame


func _process(delta: float) -> void:
	dung.rotation += WORLD_SCROLL_SPEED * DUNG_ROLL_ANIM_TRANSMISSION * delta
	
	world_bits.position += Vector2(-1, 1).normalized() * WORLD_SCROLL_SPEED * delta
	if world_bits.position[1] > Y_TO_RECENTER_WORLD:
		world_bits.position += Vector2(Y_TO_RECENTER_WORLD, -Y_TO_RECENTER_WORLD)


func play():
	SceneManager.goto_scene("res://scenes/IntroCutscene.tscn")
	SoundController.play_sfx("Play")


func show_credits():
	$Credits/Back.grab_focus()
	
	credits.show()
	main.hide()
	SoundController.play_sfx("Click")


func show_main():
	$Main/Buttons/Play.grab_focus()
	
	main.show()
	credits.hide()
	SoundController.play_sfx("Click")


func go_to_options() -> void:
	options.activate()
	
	await options.closed_menu
	
	$Main/Buttons/Options.grab_focus()


func exit() -> void:
	get_tree().quit()
