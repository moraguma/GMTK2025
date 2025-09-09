extends Node2D
class_name Menu


const CAMPAIGN_INTRO_PATHS = [
	"res://scenes/IntroCutscene.tscn"
]
const CAMPAIGN_LEADERBOARD_PATHS = [
	"res://scenes/ZeusLeaderboards.tscn"
]

const WORLD_SCROLL_SPEED = 150
const Y_TO_RECENTER_WORLD = 1920
const DUNG_ROLL_ANIM_TRANSMISSION = 0.0095


var selecting_campaign = false
var selected_campaign = -1


@onready var world_bits: Node2D = $WorldBits
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var dung: Sprite2D = $Dung
@onready var main: Node2D = $Main
@onready var credits: Node2D = $Credits
@onready var options: Options = $Options
@onready var campaign_select: Node2D = $Campaign
@onready var campaign_animation_player: AnimationPlayer = $Campaign/AnimationPlayer
@onready var campaigns = [$Campaign/ZeusContainer, $Campaign/HadesContainer]


func _ready() -> void:
	$Main/Buttons/Play.grab_focus()
	
	Globals.loop_count = 0
	
	SoundController.play_music("Menu")
	animation_player.play("roll")
	
	GlobalCamera.follow_node(self)
	GlobalCamera.snap_to_aim()
	
	RenderingServer.global_shader_parameter_set("bg_from", Color("#F0F5DD"))
	await get_tree().process_frame
	RenderingServer.global_shader_parameter_set("bg_to", Color("#ffffff"))
	await get_tree().process_frame
	RenderingServer.global_shader_parameter_set("detail_from", Color("#D3E1C8"))
	await get_tree().process_frame
	RenderingServer.global_shader_parameter_set("detail_to", Color("#C1D7B0"))
	await get_tree().process_frame
	RenderingServer.global_shader_parameter_set("ground_from", Color("#BD7F66"))
	await get_tree().process_frame
	RenderingServer.global_shader_parameter_set("ground_to", Color("#CA9072"))
	await get_tree().process_frame


func _physics_process(delta: float) -> void:
	if selecting_campaign:
		if Input.is_action_just_pressed("ui_left"):
			select_campaign(0)
		elif Input.is_action_just_pressed("ui_right"):
			select_campaign(1)
		elif Input.is_action_just_pressed("back") or Input.is_action_just_pressed("menu"):
			show_main()
			campaign_animation_player.play("disappear")


func _process(delta: float) -> void:
	dung.rotation += WORLD_SCROLL_SPEED * DUNG_ROLL_ANIM_TRANSMISSION * delta
	
	world_bits.position += Vector2(-1, 1).normalized() * WORLD_SCROLL_SPEED * delta
	if world_bits.position[1] > Y_TO_RECENTER_WORLD:
		world_bits.position += Vector2(Y_TO_RECENTER_WORLD, -Y_TO_RECENTER_WORLD)


func play():
	campaign_select.show()
	SoundController.play_sfx("Click")
	$Campaign/Buttons/Play.grab_focus()
	
	$Campaign/SelectHades.mouse_filter = Control.MOUSE_FILTER_STOP
	campaign_animation_player.play("appear")
	selecting_campaign = true


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
	
	$Campaign/SelectHades.mouse_filter = Control.MOUSE_FILTER_IGNORE
	select_campaign(-1)
	selecting_campaign = false


func go_to_options() -> void:
	options.activate()
	
	await options.closed_menu
	
	$Main/Buttons/Options.grab_focus()


func exit() -> void:
	get_tree().quit()


func select_campaign(pos: int):
	if selected_campaign == pos:
		return
	
	SoundController.play_sfx("Hover")
	selected_campaign = pos
	for i in range(len(campaigns)):
		if i == pos:
			campaigns[i].select()
		else:
			campaigns[i].deselect()


func is_campaign_unlocked():
	if selected_campaign != 0:
		GlobalCamera.add_trauma()
		SoundController.play_sfx("NoJump")
		return false
	return true


func play_campaign():
	if not is_campaign_unlocked():
		return
	SoundController.play_sfx("Play")
	SceneManager.goto_scene(CAMPAIGN_INTRO_PATHS[selected_campaign])


func go_to_campaign_leaderboards():
	if not is_campaign_unlocked():
		return
	SoundController.play_sfx("Play")
	SceneManager.goto_scene(CAMPAIGN_LEADERBOARD_PATHS[selected_campaign])
