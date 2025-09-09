extends Node2D
class_name Leaderboards


const LEADERBOARD_POSITION_SCENE = preload("res://scenes/LeaderboardPosition.tscn")
const LEADERBOARD_STOP_SCENE = preload("res://scenes/LeaderboardStop.tscn")


@export var leaderboard_name: String = "Reach Olympus"
@export var reset_scene: String = ""


@onready var global_leaderboard_base: VBoxContainer = $GlobalLeaderboard
@onready var friend_leaderboard_base: VBoxContainer = $FriendLeaderboard
@onready var loading: Panel = $Loading


var on_global = true


func _ready() -> void:
	SoundController.play_music("Menu")
	
	var handle: int = await SteamInterface.get_leaderboard_handle(leaderboard_name)
	
	if Globals.best_times[leaderboard_name] < Save.get_save_data(["best_times", leaderboard_name]):
		Save.set_save_data(["best_times", leaderboard_name], Globals.best_times[leaderboard_name])
		await SteamInterface.update_leaderboard(handle, int(Globals.best_times[leaderboard_name] * 1000.0))
	
	var global_leaderboards: Array[Array] = await SteamInterface.get_global_leaderboard(handle)
	var friend_leaderboards: Array[Array] = await SteamInterface.get_friends_leaderboard(handle)
	for i in range(len(friend_leaderboards[0])):
		friend_leaderboards[0][i]["global_rank"] = i + 1
	for i in range(len(friend_leaderboards[1])):
		friend_leaderboards[1][i]["global_rank"] = len(friend_leaderboards[0]) + i + 1
	
	populate_leaderboard(global_leaderboard_base, global_leaderboards[0], global_leaderboards[1])
	populate_leaderboard(friend_leaderboard_base, friend_leaderboards[0], friend_leaderboards[1])
	loading.hide()
	
	$GodSquisher.squish()


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		on_global = !on_global
		if on_global:
			friend_leaderboard_base.hide()
			global_leaderboard_base.show()
		else:
			friend_leaderboard_base.show()
			global_leaderboard_base.hide()
	elif Input.is_action_just_pressed("reset"):
		SceneManager.goto_scene(reset_scene)
	elif Input.is_action_just_pressed("menu"):
		SceneManager.goto_scene("res://scenes/Menu.tscn")


func insert_leaderboard_positions(leaderboard_base: VBoxContainer, leaderboard: Array) -> void:
	for entry: Dictionary in leaderboard:
		var leaderboard_position: LeaderboardPosition = LEADERBOARD_POSITION_SCENE.instantiate()
		leaderboard_base.add_child(leaderboard_position)
		leaderboard_position.initialize(entry["global_rank"], SteamInterface.get_player_name(entry["steam_id"]), entry["steam_id"], entry["score"], entry["steam_id"] == SteamInterface.get_player_id())


func populate_leaderboard(leaderboard_base: VBoxContainer, global_leaderboard: Array, local_leaderboard: Array):
	insert_leaderboard_positions(leaderboard_base, global_leaderboard)
	
	if len(local_leaderboard) > 0:
		var leaderboard_stop = LEADERBOARD_STOP_SCENE.instantiate()
		leaderboard_base.add_child(leaderboard_stop)
		insert_leaderboard_positions(leaderboard_base, local_leaderboard)
