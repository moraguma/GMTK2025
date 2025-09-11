extends Object
class_name Steamworks


signal get_name(user_id, user_name)


func connect_callbacks() -> void:
	Steam.persona_state_change.connect(
		func(steam_id, flag):
			if flag == Steam.PERSONA_CHANGE_NAME:
				get_name.emit(steam_id, Steam.getFriendPersonaName(steam_id))
	)


func initialize_steam(app_id: int) -> void:
	var initialize_response: Dictionary = Steam.steamInitEx(app_id)
	print("Initializing Steam...\n%s" % [initialize_response])


func run_callbacks() -> void:
	Steam.run_callbacks()


## Coroutine that returns the leaderboard handle. Returns -1 if the
## leaderboard couldn't be found
func get_leaderboard_handle(leaderboard_name: String) -> int:
	Steam.findLeaderboard(leaderboard_name)
	
	var args = await Steam.leaderboard_find_result
	
	if args[1] == 1:
		return args[0]
	return -1


## Coroutine that updates the leaderboard. Returns whether the operation was
## successful
func update_leaderboard(leaderboard_handle: int, score: int) -> bool:
	Steam.uploadLeaderboardScore(score, true, PackedInt32Array(), leaderboard_handle)
	
	var args = await Steam.leaderboard_score_uploaded
	
	return args[0]


## Filters the leaderboards, removing repeated entries from local leaderboard
func filter_leaderboard(global_leaderboard: Array, local_leaderboard: Array) -> Array[Array]:
	while len(local_leaderboard) > 0 and local_leaderboard[0]["global_rank"] <= 10:
		local_leaderboard.remove_at(0)
	return [global_leaderboard, local_leaderboard]


## Returns the top 10 global players in the leaderboard as well as the 5 closest
## players relative to the user. If friends is true, considers only the user's
## friends
func get_global_leaderboard(leaderboard_handle: int) -> Array[Array]:
	Steam.downloadLeaderboardEntries(1, 10, Steam.LEADERBOARD_DATA_REQUEST_GLOBAL, leaderboard_handle)
	
	var global_args = await Steam.leaderboard_scores_downloaded
	var global_leaderboard: Array = global_args[2].duplicate()
	
	Steam.downloadLeaderboardEntries(-3, 1, Steam.LEADERBOARD_DATA_REQUEST_GLOBAL_AROUND_USER, leaderboard_handle)
	
	var local_args = await Steam.leaderboard_scores_downloaded
	var local_leaderboard: Array = local_args[2].duplicate()
	
	return filter_leaderboard(global_leaderboard, local_leaderboard)


## Same as get_global_leaderboard, but only considers friends
func get_friends_leaderboard(leaderboard_handle: int) -> Array[Array]:
	Steam.downloadLeaderboardEntries(0, 0, Steam.LEADERBOARD_DATA_REQUEST_FRIENDS, leaderboard_handle)
	
	var friend_args = await Steam.leaderboard_scores_downloaded
	var friend_leaderboard: Array = friend_args[2]
	
	var global_leaderboard: Array = []
	var local_leaderboard: Array = []
	
	for i in range(0, min(len(friend_leaderboard), 10)):
		global_leaderboard.append(friend_leaderboard[i])
	
	for i in range(0, len(friend_args)):
		if friend_leaderboard[i]["steam_id"] == Steam.current_steam_id:
			for j in range(max(0, i - 3), min(len(friend_leaderboard), i + 1)):
				local_leaderboard.append(friend_leaderboard[i])
			break
	
	return filter_leaderboard(global_leaderboard, local_leaderboard)


## Returns the player's Steam id
func get_player_id() -> int:
	return Steam.current_steam_id


## Gets a player's name by steam_id. Returns "" if isn't yet friend
func request_player_name(steam_id: int) -> String:
	var success = Steam.requestUserInformation(steam_id, true)
	
	var name = Steam.getFriendPersonaName(steam_id)
	if name == "":
		return "???"
	return name


## Open Steam overlay on specified webpage
func go_to_store(app_id: int) -> void:
	Steam.activateGameOverlayToStore(app_id)
