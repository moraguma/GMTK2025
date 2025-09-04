extends Node


signal get_name(user_id, user_name)


const APP_ID = 3971000


@export var steam_on: bool = true


@onready var steamworks: Steamworks = Steamworks.new() if steam_on else null


func _ready() -> void:
	if steamworks:
		steamworks.connect_callbacks()
		steamworks.get_name.connect(
			func(user_id, user_name):
				get_name.emit(user_id, user_name)
		)


func _process(delta: float) -> void:
	if steamworks:
		steamworks.run_callbacks()


## Coroutine that returns the leaderboard handle. Returns -1 if the
## leaderboard couldn't be found
func get_leaderboard_handle(leaderboard_name: String) -> int:
	if steamworks:
		return await steamworks.get_leaderboard_handle(leaderboard_name)
	return -1


## Coroutine that updates the leaderboard. Returns whether the operation was
## successful
func update_leaderboard(leaderboard_handle: int, score: int) -> bool:
	if steamworks:
		return await steamworks.update_leaderboard(leaderboard_handle, score)
	return false


## Returns the top 10 global players in the leaderboard as well as the 5 closest
## players relative to the user. If friends is true, considers only the user's
## friends
func get_global_leaderboard(leaderboard_handle: int) -> Array[Array]:
	if steamworks:
		return await steamworks.get_global_leaderboard(leaderboard_handle)
	return [[], []]


## Same as get_global_leaderboard, but only considers friends
func get_friends_leaderboard(leaderboard_handle: int) -> Array[Array]:
	if steamworks:
		return await steamworks.get_friends_leaderboard(leaderboard_handle)
	return [[], []]


## Returns the player's Steam id
func get_player_id() -> int:
	if steamworks:
		return steamworks.get_player_id()
	return -1


## Gets a player's name by steam_id
func get_player_name(steam_id: int) -> String:
	if steamworks:
		return steamworks.request_player_name(steam_id)
	return ""
