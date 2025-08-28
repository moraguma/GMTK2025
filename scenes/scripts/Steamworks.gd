extends Object
class_name Steamworks


func initialize_steam(app_id: int) -> void:
	var initialize_response: Dictionary = Steam.steamInitEx(app_id)
	print("Initializing Steam...\n%s" % [initialize_response])


func run_callbacks() -> void:
	Steam.run_callbacks()
