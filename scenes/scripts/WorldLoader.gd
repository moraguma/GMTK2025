extends Node2D
class_name WorldLoader

signal started_transition(transition_vector)
signal finished_transition
signal finished_transition_process

const PLAYER_SCENE = preload("res://scenes/entities/Player.tscn")

const TRANSITION_TIME = 0.6
const TRANSITION_BUFFER_TIME = 0.1
const PLAYER_TRANSITION_MOVEMENT_H = 24.0
const PLAYER_TRANSITION_MOVEMENT_V = 32.0
const PLAYER_VERTICAL_TRANSITION_SPEED = 220.0
const MOVEMENT_EXCEPTIONS = ["Rope"]

const V_DEATH_TOLERANCE = 8
const H_DEATH_TOLERANCE = 32
const ACTIVATION_TIME = 0.2

# Zoom
const GAME_RESOLUTION = Vector2i(384, 216)

# Player arrow
const ARROW_TOLERANCE = 8.0
const ARROW_MIN_SCALE = 0.5
const ARROW_MAX_DIST = 60.0

# Announcements
const ANNOUNCEMENT_TIME = 3.5
const TIME_BEFORE_ANNOUNCEMENT = 2.0
const AREA_TO_ANNOUNCEMENT = {
	0: "somewhere_old",
	1: "somewhere_lush",
	2: "somewhere_cold"
}
const AREA_TO_TRACK = {
	0: "Old",
	1: "Soft",
	2: "Cold"
}

# Visual
const TOTAL_RECOVERS = 50
const RECOVER_SCENE = preload("res://scenes/entities/visual/Recover.tscn")

# ------------------------------------------------------------------------------
# VARIABLES
# ------------------------------------------------------------------------------
@export var debug_level_path: String

var spawn_pos: Vector2
var spawn_flipped: bool
var current_level_path: String

var grapple = null

# Zoom
@onready var WIDTH = ProjectSettings.get_setting("display/window/size/viewport_width")
@onready var HEIGHT = ProjectSettings.get_setting("display/window/size/viewport_height")
@onready var GAME_ZOOM = WIDTH / float(GAME_RESOLUTION[0])

# Mouse
var player_using_mouse = true
var mouse_indicator_visible = true

# Console
var level_borders_enabled = true

# Visual
var recovers: Array[Recover] = []
var recover_pos = 0
var recover_to_pos: Dictionary = {}
var pos_to_recover: Dictionary = {}


# ------------------------------------------------------------------------------
# NODES
# ------------------------------------------------------------------------------

@onready var pause_menu: PauseMenu = $PauseContainer/Pause
@onready var map: MapBase = $PauseContainer/Pause/Base/SubmenuHolder/Map/Main/Base/MapHolder/MapPivot/Map

@onready var view: ScalableView = $View
@onready var viewport = $Viewport
@onready var blocker: ColorRect = $Blocker
@onready var player_arrow: Sprite2D = $PlayerArrow
@onready var mouse_aim_indicator: FollowScreenNode = $MouseAimIndicator/Offset/MouseAimIndicator
@onready var visual_elements: Node2D = $VisualElements

@onready var world_base: Node2D = $Viewport/WorldBase
@onready var world_camera: WorldCamera = $Viewport/WorldCamera
@onready var recover_container: Node2D = $Viewport/RecoverContainer
@onready var world_notifier: WorldNotifier = $WorldNotifier

@onready var area_anouncer: Label = $AreaAnouncer
@onready var area_anouncer_timer: Timer = $AreaAnouncer/Timer

@onready var activation_timer: Timer = $ActivationTimer

var player: Player
var can_pause = true

var can_zoom = true
var locked_camera_console = false


enum CHUNK_STATE {LOADING, LOADED}


const CHUNK_SIZE = Vector2(576, 576)
const ROOM_EXTRA_SIZE = Vector2(8, 8)
const PHYSICS_PROCESS_PRIORITY = 1
const CAMERA_TIME_ORIGIN_SHIFT = 5000.0
const INITIALIZATION_TIME = 0.5



## Stores loaded and loading chunks. For each chunk position, stores:
## {
##    chunk_pos: {
##        "state": loaded/loading
##        "chunk": chunk if loaded, chunk_path if loading
## }
var chunks: Dictionary = {}
var current_chunk_pos: Vector2i
var current_room: String
var chunk_shift: Vector2i = Vector2i(0, 0)
@onready var time_since_camera_on_player = Time.get_ticks_msec()
var initialized = false


# ------------------------------------------------------------------------------
# BUILT-INS
# ------------------------------------------------------------------------------
## Initialize console commands
func _enter_tree() -> void:
	Console.add_command("toggle_borders", toggle_level_borders, [], 0, "Enables or disables screen transitions and OOB deaths")
	Console.add_command("toggle_indicators", toggle_indicator_visibility, [], 0, "Enables or disables grapple indicators")
	Console.add_command("zoom", zoom_console, ["factor"], 1, "Sets zoom by this factor")
	Console.add_command("lock", lock_console, ["screens_x", "screens_y"], 2, "Locks camera to specified position")
	Console.add_command("cam_mode", console_set_camera_mode, ["camera_mode"], 1, "Sets camera mode to either normal or debug")


## Erase console commands
func _exit_tree() -> void:
	Console.remove_command("toggle_borders")
	Console.remove_command("toggle_indicators")
	Console.remove_command("zoom")
	Console.remove_command("lock")
	Console.remove_command("cam_mode")


func _ready():
	process_physics_priority = PHYSICS_PROCESS_PRIORITY
	
	Globals.world_loader = self
	GlobalCamera.follow_node(view)
	GlobalCamera.snap_to_aim()
	zoom_by(1.0)
	
	# Sound
	if Save.get_save_data(["position", "area_announced"]):
		SoundController.play_track(AREA_TO_TRACK[Save.get_save_data(["position", "area"])] + "Fade")
	else:
		SoundController.stop_track()
	
	# Load initial chunks
	current_chunk_pos = Save.get_save_data(["position", "current_chunk"])
	for x in range(-1, 2):
		for y in range(-1, 2):
			var chunk_pos = current_chunk_pos + Vector2i(x, y)
			var chunk_path = get_chunk_path(chunk_pos)
			var chunk: Chunk = load(get_chunk_path(chunk_pos)).instantiate() as Chunk if chunk_path != null else Chunk.new()
			add_chunk(chunk_pos, chunk)
			
			chunks[chunk_pos] = {
				"state": CHUNK_STATE.LOADED,
				"chunk": chunk
			}
	
	# Load level
	current_room = Save.get_save_data(["position", "current_room"])
	
	# Load player
	player = PLAYER_SCENE.instantiate()
	world_base.add_child(player)
	player.position = Save.get_save_data(["position", "spawn_pos"])
	player.set_flipped(Save.get_save_data(["position", "spawn_flipped"]))
	
	world_camera.aim_node = player
	mouse_aim_indicator.follow = player
	
	world_camera.set_limits(Globals.constants.room_data[current_room]["size"])
	world_camera.snap_limits()
	world_camera.snap_to_aim.call_deferred()
	
	get_tree().create_timer(INITIALIZATION_TIME).timeout.connect(func(): initialized = true)
	
	InputHelper.device_changed.connect(update_player_using_mouse)
	update_player_using_mouse(InputHelper.device, InputHelper.device_index)
	
	# Load recovers
	for i in range(TOTAL_RECOVERS):
		var recover = RECOVER_SCENE.instantiate()
		recover_container.add_child(recover)
		recovers.append(recover)


func _physics_process(delta: float) -> void:
	_pause_process()
	_update_chunk_position()
	_update_queued_chunks()
	_update_room()
	_check_player_pos()


func _pause_process() -> void:
	var menu_pressed = Input.is_action_just_pressed("menu") and can_pause
	var map_pressed = Input.is_action_just_pressed("map") and can_pause
	if menu_pressed or map_pressed:
		pause_menu.open(map_pressed)
		
		pause_game()
		await pause_menu.closed
		unpause_game()


## Checks if player has moved out of current chunk. If so, unloads old chunks
## and queues loading of old ones
func _update_chunk_position():
	# Get player's local chunk
	var local_chunk = get_chunk_position(player.position)
	
	# Return if in origin chunk
	if local_chunk == chunk_shift:
		return
	
	current_chunk_pos += local_chunk - chunk_shift
	chunk_shift = local_chunk
	
	# Delete old chunks
	for chunk_pos in chunks.keys():
		var chunk_dif = abs(chunk_pos - current_chunk_pos)
		if chunk_dif[0] > 1 or chunk_dif[1] > 1:
			if chunks[chunk_pos]["state"] == CHUNK_STATE.LOADED:
				chunks[chunk_pos]["chunk"].queue_free()
			chunks.erase(chunk_pos)
	
	# Queue loading of new chunks
	for x in range(-1, 2):
		for y in range(-1, 2):
			var chunk_pos = current_chunk_pos + Vector2i(x, y)
			if not chunk_pos in chunks:
				var chunk_path = get_chunk_path(chunk_pos)
				if chunk_path == null:
					var new_chunk = Chunk.new()
					add_chunk(chunk_pos, new_chunk)
					chunks[chunk_pos] = {
						"state": CHUNK_STATE.LOADED,
						"chunk": new_chunk
					}
				else:
					ResourceLoader.load_threaded_request(chunk_path)
					chunks[chunk_pos] = {
						"state": CHUNK_STATE.LOADING,
						"chunk": chunk_path
					}


func _shift_origin():
	var current_time = Time.get_ticks_msec()
	if world_camera.aim_node == player:
		time_since_camera_on_player = current_time
	
	if chunk_shift == Vector2i(0, 0):
		return
	print("Shifted origin from %s to %s" % [current_chunk_pos - chunk_shift, current_chunk_pos])
	
	# Shifting origin
	var adjustment_vector = -Vector2(chunk_shift) * CHUNK_SIZE
	for child in world_base.get_children():
		var is_excepted = false
		for movement_exception in MOVEMENT_EXCEPTIONS:
			if child.name.contains(movement_exception):
				is_excepted = true
				break
		
		if not is_excepted:
			child.position += adjustment_vector
	world_camera.adjust(adjustment_vector)
	get_tree().call_group("adjustable", "adjust", adjustment_vector)
	world_camera.snap_to_aim()
	
	chunk_shift = Vector2i(0, 0)


## Runs through loading chunks. Adds the first loaded one that's available
func _update_queued_chunks():
	for chunk_pos in chunks:
		if chunks[chunk_pos]["state"] == CHUNK_STATE.LOADING and ResourceLoader.load_threaded_get_status(chunks[chunk_pos]["chunk"]) == ResourceLoader.THREAD_LOAD_LOADED:
			var new_chunk = ResourceLoader.load_threaded_get(chunks[chunk_pos]["chunk"]).instantiate() as Chunk
			add_chunk(chunk_pos, new_chunk)
			chunks[chunk_pos]["state"] = CHUNK_STATE.LOADED
			chunks[chunk_pos]["chunk"] = new_chunk
			break


## Updates the room player is currently in
func _update_room():
	var current_room_rect = get_room_rect(current_room)
	current_room_rect.position -= ROOM_EXTRA_SIZE
	current_room_rect.size += ROOM_EXTRA_SIZE * 2
	
	if not current_room_rect.has_point(player.position):
		for adjacent_room in Globals.constants.room_data[current_room]["neighbors"]:
			var adjacent_room_rect = get_room_rect(adjacent_room)
			if adjacent_room_rect.has_point(player.position):
				current_room = adjacent_room
				
				var transition_dir = Vector2(0, 0)
				if player.position[0] > current_room_rect.position[0] and player.position[0] < current_room_rect.position[0] + current_room_rect.size[0]:
					transition_dir[1] += 1 if adjacent_room_rect.position[1] > current_room_rect.position[1] else -1
				if player.position[1] > current_room_rect.position[1] and player.position[1] < current_room_rect.position[1] + current_room_rect.size[1]:
					transition_dir[0] += 1 if adjacent_room_rect.position[0] > current_room_rect.position[0] else -1
				world_camera.set_limits(Globals.constants.room_data[current_room]["size"], transition_dir)
				
				var new_spawn_pos = null
				var best_distance = 9999
				for spawn_pos in Globals.constants.room_data[current_room]["spawn_positions"]:
					var global_spawn_pos = adjacent_room_rect.position + spawn_pos
					var distance = (global_spawn_pos - player.position).length()
					if distance < best_distance:
						best_distance = distance
						new_spawn_pos = global_spawn_pos
				if new_spawn_pos != null:
					Save.set_save_datas(
						[["current_chunk"], ["current_room"], ["spawn_pos"], ["spawn_flipped"]],
						[current_chunk_pos, current_room, new_spawn_pos - Vector2(chunk_shift) * CHUNK_SIZE, (new_spawn_pos - player.position)[0] < 0],
						["position"]
					)
				
				
				Save.set_save_datas([["level_name"], ["levels_entered", current_room]], [current_room, true], ["map"])
				map.level_entered(current_room)
				
				Save.save_game()
				
				world_camera.update_room()
				
				_shift_origin()
				world_notifier.stop_displaying()
				break


## Checks the position of the player, killing them if they're outside the current room by too big a
## margin and adding and arrow if they're just a bit outside
func _check_player_pos():
	if player.in_cutscene:
		return
	
	var limits = world_camera.get_effective_limits()
	
	if player.position[0] < limits[0] - H_DEATH_TOLERANCE:
		player.die(Vector2(1, 0))
	elif player.position[0] > limits[2] + H_DEATH_TOLERANCE:
		player.die(Vector2(-1, 0))
	elif player.position[1] > limits[3] + V_DEATH_TOLERANCE:
		player.die(Vector2(0, -1))


func _process(delta):
	_arrow_process()


func _arrow_process():
	var player_dif = player.position - world_camera.get_screen_center_position()
	player_dif[1] += GAME_RESOLUTION[1] / 2 + ARROW_TOLERANCE
	if player_dif[1] < 0 and level_borders_enabled:
		player_arrow.show()
		player_arrow.position[0] = player_dif[0] / GAME_RESOLUTION[0] * Globals.SCREEN_SIZE[0] 
		var scale_factor = lerp(1.0, ARROW_MIN_SCALE, min(player_dif[1] / -ARROW_MAX_DIST, 1.0))
		player_arrow.scale = Vector2(scale_factor, scale_factor)
	else:
		player_arrow.hide()


## Returns the player's vector outside its current room considering that the 
## room is threshold pixels smaller in all directions
func get_player_room_dif(threshold):
	var room_rect = get_room_rect(current_room)
	var neighbor_rects = []
	for neighbor in Globals.constants.room_data[current_room]["neighbors"]:
			neighbor_rects.append(get_room_rect(neighbor))
	
	var result = Vector2(0, 0)
	for axis in [0, 1]:
		# Check if there's room nearby
		var room_checker = Vector2(0, 0)
		room_checker[axis] = threshold
		var found_neighbor = false
		for neighbor_rect in neighbor_rects:
			if neighbor_rect.has_point(player.position + room_checker) or neighbor_rect.has_point(player.position - room_checker):
				found_neighbor = true
				break
		if not found_neighbor:
			continue
		
		# Calculate dif
		var dif = 0
		var upper_limit = room_rect.position[axis] + room_rect.size[axis] - threshold
		var lower_limit = room_rect.position[axis] + threshold
		if player.position[axis] > upper_limit:
			dif = player.position[axis] - upper_limit
		elif player.position[axis] < lower_limit:
			dif = player.position[axis] - lower_limit
		result[axis] = dif
	
	return result


func update_spawn_pos(spawn_pos, spawn_flipped):
	Save.set_save_datas(
		[["spawn_pos"], ["spawn_flipped"]],
		[spawn_pos - Vector2(chunk_shift) * CHUNK_SIZE, (spawn_pos - player.position)[0] < 0],
		["position"]
	)


func room_to_chunk_coords(pos: Vector2) -> Vector2:
	var room_data = Globals.constants.room_data[current_room]
	return Vector2(chunk_shift + room_data["chunk"] - current_chunk_pos) * CHUNK_SIZE + room_data["pos"] + pos


func chunk_to_room_coords(pos: Vector2) -> Vector2:
	var room_data = Globals.constants.room_data[current_room]
	return pos - (CHUNK_SIZE * Vector2(room_data["chunk"] - current_chunk_pos + chunk_shift) + room_data["pos"])


func get_room_rect(room_name):
	var room_data = Globals.constants.room_data[room_name]
	return Rect2(Vector2(chunk_shift + room_data["chunk"] - current_chunk_pos) * CHUNK_SIZE + room_data["pos"], room_data["size"])


func get_chunk_position(pos: Vector2):
	return Vector2i(floor((pos[0] - fposmod(pos[0], CHUNK_SIZE[0])) / CHUNK_SIZE[0]), floor((pos[1] - fposmod(pos[1], CHUNK_SIZE[1])) / CHUNK_SIZE[1]))


func add_chunk(chunk_pos: Vector2i, chunk: Chunk):
	chunk.position = Vector2(chunk_shift + chunk_pos - current_chunk_pos) * CHUNK_SIZE
	world_base.add_child(chunk)


## Returns the path for the chunk in the specified position, or null if there is
## no chunk
func get_chunk_path(chunk_pos: Vector2i):
	var path = "res://scenes/world/chunks/" + str(chunk_pos[0]) + "_" + str(chunk_pos[1]) + ".tscn"
	if ResourceLoader.exists(path):
		return path
	return null


func is_node_inside_current_room(node: Node2D) -> bool:
	var room_rect = get_room_rect(current_room)
	return room_rect.has_point(node.global_position)


## Updates whether player is using mouse controls and mouse indicator visibility
func update_player_using_mouse(device: String, device_idx) -> void:
	player_using_mouse = device == InputHelper.DEVICE_KEYBOARD and player.aiming_style == Player.AimingStyle.CAREFUL and player.has_grapple_ability
	update_mouse_indicator_visibility()


## Applies a zoom by the given factor
func zoom_by(factor: float, adjust_limits: bool=false):
	if not can_zoom:
		return
	zoom_by_vector(factor * Vector2(GAME_ZOOM, GAME_ZOOM), adjust_limits)
	## TEMP


## Snaps to aim_zoom
func snap_zoom() -> void:
	view.snap_zoom()
	## TEMP


## Applies a zoom by the given vector
func zoom_by_vector(zoom: Vector2, adjust_limits: bool=false):
	if not can_zoom:
		return
	
	if view.aim_zoom != null and adjust_limits:
		var rel_factor: float = zoom[0] / view.aim_zoom[0]
		var dir: float = 1.0
		if rel_factor < 1.0:
			dir = -1.0
			rel_factor = 1 / rel_factor
		#var f = dir / (1.8 * rel_factor)
		#world_camera.aim_limits[0] -= int(f * GAME_RESOLUTION[0])
		#world_camera.aim_limits[1] -= int(f * GAME_RESOLUTION[1])
		#world_camera.aim_limits[2] += int(f * GAME_RESOLUTION[0])
		#world_camera.aim_limits[3] += int(f * GAME_RESOLUTION[1])
	
	view.aim_zoom = zoom
	## TEMP


## Calls for a notification from the WorldNotifier
func notify(notification: Array[Dictionary]) -> void:
	world_notifier.display(notification)
	## TEMP


## Announces area name if not yet announced
func announce(area: Globals.Area) -> void:
	if not Save.get_save_data(["position", "area_announced"]):
		Save.set_save_data(["position", "area_announced"], true)
		Save.save_game()
		
		area_anouncer_timer.start(TIME_BEFORE_ANNOUNCEMENT)
		await area_anouncer_timer.timeout
		
		area_anouncer.text = TranslationManager.get_translation(AREA_TO_ANNOUNCEMENT[area])
		
		if world_camera.mode != world_camera.Mode.DEBUG:
			area_anouncer.show()
		
		area_anouncer_timer.start(ANNOUNCEMENT_TIME)
		SoundController.play_track(AREA_TO_TRACK[area] + "Stinger")
		await area_anouncer_timer.timeout
		area_anouncer.hide()


## Asks for a reset of the current level
func queue_reset():
	can_pause = false
	Globals.world_loader = null
	SceneManager.goto_scene("res://scenes/world/WorldLoader.tscn")


# Pause ------------------------------------------------------------------------
## Pauses processing. Mostly for pause menu
func pause_game() -> void:
	get_tree().paused = true
	update_mouse_indicator_visible(false)


## Continues processing. Mostly for pause menu
func unpause_game() -> void:
	get_tree().paused = false
	update_mouse_indicator_visible(true)


## Updates if mouse indicator should be visible and its visibility
func update_mouse_indicator_visible(val: bool) -> void:
	mouse_indicator_visible = val
	update_mouse_indicator_visibility()


## Updates mouse indicator visibility based on if it should be visible and if
## the player is using the mouse
func update_mouse_indicator_visibility() -> void:
	if mouse_indicator_visible and player_using_mouse:
		mouse_aim_indicator.show()
	else:
		mouse_aim_indicator.hide()


## Creates a recover animation in the specified position and 
func animate_recover(attach: Node2D, pos: Vector2, green: bool):
	# Remove stale references
	if recovers[recover_pos] in recover_to_pos:
		pos_to_recover.erase(recover_to_pos[recovers[recover_pos]])
	
	# If recover exists in aimed position, deactivate it
	var relative_pos = pos - attach.global_position
	if relative_pos in pos_to_recover:
		pos_to_recover[relative_pos].deactivate()
		recover_to_pos.erase(pos_to_recover[relative_pos])
	
	# Update references
	pos_to_recover[relative_pos] = recovers[recover_pos]
	recover_to_pos[recovers[recover_pos]] = relative_pos
	
	# Activate recover
	recovers[recover_pos].activate(attach, pos, green)
	recover_pos += 1
	if recover_pos >= TOTAL_RECOVERS:
		recover_pos = 0


# ------------------------------------------------------------------------------
# Console commands
# ------------------------------------------------------------------------------
func toggle_level_borders():
	level_borders_enabled = !level_borders_enabled
	Console.print_line("Level borders are now " + ("on" if level_borders_enabled else "off"))


func toggle_indicator_visibility():
	player.indicators_visible = !player.indicators_visible
	player.update_indicator_visibility(false)
	Console.print_line("Indicators are now " + ("visible" if player.indicators_visible else "invisible"))


func zoom_console(factor):
	var ff = float(factor)
	can_zoom = true
	world_camera.enable_limits()
	
	zoom_by(ff, true)
	
	if ff != 1.0:
		can_zoom = false
		world_camera.disable_limits()


func lock_console(x, y):
	if locked_camera_console:
		world_camera.load_state()
	if float(x) == 0 or float(y) == 0:
		locked_camera_console = false
		return
	
	locked_camera_console = true
	world_camera.save_state()
	var pos = Vector2(float(x) * GAME_RESOLUTION[0], float(y) * GAME_RESOLUTION[1])
	world_camera.follow_pos(pos)


func console_set_camera_mode(mode):
	match mode.to_lower():
		"normal":
			world_camera.mode = world_camera.Mode.FOLLOW
		"debug":
			world_camera.mode = world_camera.Mode.DEBUG


"""
# ------------------------------------------------------------------------------
# BUILT-INS
# ------------------------------------------------------------------------------
## Initialize console commands
func _enter_tree() -> void:
	Console.add_command("toggle_borders", toggle_level_borders, [], 0, "Enables or disables screen transitions and OOB deaths")
	Console.add_command("toggle_indicators", toggle_indicator_visibility, [], 0, "Enables or disables grapple indicators")
	Console.add_command("zoom", zoom_console, ["factor"], 1, "Sets zoom by this factor")
	Console.add_command("lock", lock_console, ["screens_x", "screens_y"], 2, "Locks camera to specified position")


## Erase console commands
func _exit_tree() -> void:
	Console.remove_command("toggle_borders")
	Console.remove_command("toggle_indicators")
	Console.remove_command("zoom")
	Console.remove_command("lock")


func _ready():
	Globals.world_loader = self
	
	# Camera
	GlobalCamera.follow_node(view)
	GlobalCamera.snap_to_aim()
	
	zoom_by(1.0)
	
	# Sound
	if Save.get_save_data(["position", "area_announced"]):
		SoundController.play_track(AREA_TO_TRACK[Save.get_save_data(["position", "area"])] + "Fade")
	else:
		SoundController.stop_track()
	
	if player == null:
		var level
		
		if debug_level_path != "":
			level = load(debug_level_path).instantiate()
			var transition: LevelTransition = level.get_node("Transitions").get_child(0)
			spawn_pos = transition.spawn_pos
			spawn_flipped = transition.spawn_flipped
		else:
			level = load(Save.get_save_data(["position", "level_path"])).instantiate()
			spawn_pos = Save.get_save_data(["position", "spawn_pos"])
			spawn_flipped = Save.get_save_data(["position", "spawn_flipped"])
		start_level(level, spawn_pos, spawn_flipped)
		finished_transition.emit.call_deferred()
	
	# Controls
	InputHelper.device_changed.connect(update_player_using_mouse)
	update_player_using_mouse(InputHelper.device, InputHelper.device_index)





func _physics_process(delta):
	var menu_pressed = Input.is_action_just_pressed("menu") and can_pause
	var map_pressed = Input.is_action_just_pressed("map") and can_pause
	if menu_pressed or map_pressed:
		pause_menu.open(map_pressed)
		
		pause_game()
		await pause_menu.closed
		unpause_game()
	
	if level_borders_enabled:
		if player.position[0] < -H_DEATH_TOLERANCE:
			player.die(Vector2(1, 0))
		elif player.position[0] > world_camera.limit_right + H_DEATH_TOLERANCE:
			player.die(Vector2(-1, 0))
		elif player.position[1] > world_camera.limit_bottom + V_DEATH_TOLERANCE:
			player.die(Vector2(0, -1))


# ------------------------------------------------------------------------------
# METHODS
# ------------------------------------------------------------------------------
# World management -------------------------------------------------------------
func update_spawn_pos(new_spawn_pos: Vector2, new_spawn_flipped: bool):
	spawn_pos = new_spawn_pos
	spawn_flipped = new_spawn_flipped
	Save.set_save_datas([["spawn_pos"], ["spawn_flipped"]], [spawn_pos, spawn_flipped], ["position"])


func add_scene(node: Node2D):
	world_base.call_deferred("add_child", node)


func load_level(level_path: String, new_spawn_pos: Vector2, new_spawn_flipped: bool):
	start_level(load(level_path).instantiate(), new_spawn_pos, new_spawn_flipped)


func start_level(level, new_spawn_pos: Vector2, new_spawn_flipped: bool):
	spawn_pos = new_spawn_pos
	spawn_flipped = new_spawn_flipped
	
	player = PLAYER_SCENE.instantiate()
	world_base.add_child(player)
	
	player.position = spawn_pos
	player.set_flipped(spawn_flipped)
	world_camera.follow_node(player)
	mouse_aim_indicator.follow = player
	
	add_scene(level)
	
	world_camera.set_limits([0.0, 0.0, level.size[0], level.size[1]], level.position)
	world_camera.update_limits()
	world_camera.snap_to_aim.call_deferred()
	
	level_activate()


## Moves the camera to focus on the new level. Takes the vector that the camera should move by as
## well as the direction the player is traversing through. Boundaries should be given as left, top, 
## right, bottom
func transition(next_level_transition: LevelTransition, transition_dir: Vector2, boundaries: Array[float], new_scene, level_path: String):
	started_transition.emit(transition_dir * Vector2(GAME_RESOLUTION))
	
	player.start_transition()
	
	if grapple.force_unstick():
		grapple.destroy_joints()
	end_notification()
	
	zoom_by(1.0)
	
	current_level_path = level_path
	spawn_pos = next_level_transition.position + next_level_transition.spawn_pos
	spawn_flipped = next_level_transition.spawn_flipped
	
	# Update save
	Save.set_save_datas([["level_path"], ["spawn_pos"], ["spawn_flipped"]], [current_level_path, spawn_pos, spawn_flipped], ["position"])
	
	var level_name = level_path.split("/")[-1].replace(".tscn", "")
	Save.set_save_datas([["level_name"], ["levels_entered", level_name]], [level_name, true], ["map"])
	map.level_entered(level_name)
	
	Save.save_game()
	
	get_tree().paused = true
	
	player.aim_indicator.pos = Vector2(-999, -999) # Make indicator invisible
	
	var transition_vector = transition_dir * Vector2(GAME_RESOLUTION)
	var initial_camera_pos = world_camera.get_screen_center_position()
	transition_vector[0] = min(transition_vector[0], boundaries[2] - GAME_RESOLUTION[0] / 2 - initial_camera_pos[0])
	transition_vector[0] = max(transition_vector[0], boundaries[0] + GAME_RESOLUTION[0] / 2 - initial_camera_pos[0])
	transition_vector[1] = min(transition_vector[1], boundaries[3] - GAME_RESOLUTION[1] / 2 - initial_camera_pos[1])
	transition_vector[1] = max(transition_vector[1], boundaries[1] + GAME_RESOLUTION[1] / 2 - initial_camera_pos[1])
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CIRC)
	tween.set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	tween.tween_property(world_base, "position", world_base.position - transition_vector, TRANSITION_TIME)
	tween.tween_property(player, "position", player.position + transition_dir * (PLAYER_TRANSITION_MOVEMENT_H if transition_dir[0] != 0 else PLAYER_TRANSITION_MOVEMENT_V), TRANSITION_TIME)
	
	await tween.finished
	
	world_base.position += transition_vector
	
	var adjustment_vector = - new_scene.position
	for child in world_base.get_children():
		var is_excepted = false
		for movement_exception in MOVEMENT_EXCEPTIONS:
			if child.name.contains(movement_exception):
				is_excepted = true
				break
		
		if not is_excepted:
			child.position += adjustment_vector
	
	var camera_pos = initial_camera_pos + transition_vector + adjustment_vector
	if world_camera.limits_active:
		world_camera.current_ambience.position = camera_pos
		world_camera.position = camera_pos
	else:
		world_camera.position = player.position
		world_camera.current_ambience.position = player.position
	world_camera.set_limits(boundaries, -adjustment_vector, transition_dir)
	
	if transition_dir == Vector2(0, -1):
		player.override_velocity(-PLAYER_VERTICAL_TRANSITION_SPEED, 1)
	
	get_tree().paused = false
	
	level_activate()
	player.finish_transition()
	
	finished_transition_process.emit()
	await get_tree().create_timer(TRANSITION_BUFFER_TIME).timeout
	finished_transition.emit()


func level_activate():
	activation_timer.start(ACTIVATION_TIME)


## Asks for a reset of the current level
func queue_reset():
	can_pause = false
	Globals.world_loader = null
	SceneManager.goto_scene("res://scenes/world/WorldLoader.tscn")





# Camera -----------------------------------------------------------------------
## Applies a zoom by the given factor
func zoom_by(factor: float, adjust_limits: bool=false):
	if not can_zoom:
		return
	zoom_by_vector(factor * Vector2(GAME_ZOOM, GAME_ZOOM), adjust_limits)


## Snaps to aim_zoom
func snap_zoom() -> void:
	view.snap_zoom()


## Applies a zoom by the given vector
func zoom_by_vector(zoom: Vector2, adjust_limits: bool=false):
	if not can_zoom:
		return
	
	if view.aim_zoom != null and adjust_limits:
		var rel_factor: float = zoom[0] / view.aim_zoom[0]
		var dir: float = 1.0
		if rel_factor < 1.0:
			dir = -1.0
			rel_factor = 1 / rel_factor
		var f = dir / (1.8 * rel_factor)
		world_camera.aim_limits[0] -= int(f * GAME_RESOLUTION[0])
		world_camera.aim_limits[1] -= int(f * GAME_RESOLUTION[1])
		world_camera.aim_limits[2] += int(f * GAME_RESOLUTION[0])
		world_camera.aim_limits[3] += int(f * GAME_RESOLUTION[1])
	
	view.aim_zoom = zoom


# Visual elements --------------------------------------------------------------
## Updates whether player is using mouse controls and mouse indicator visibility
func update_player_using_mouse(device: String, device_idx) -> void:
	player_using_mouse = device == InputHelper.DEVICE_KEYBOARD and player.aiming_style == Player.AimingStyle.CAREFUL and player.has_grapple_ability
	update_mouse_indicator_visibility()








## Calls for a notification from the WorldNotifier
func notify(notification: Array[Dictionary]) -> void:
	world_notifier.display(notification)


## Announces area name if not yet announced
func announce(area: Globals.Area) -> void:
	if not Save.get_save_data(["position", "area_announced"]):
		Save.set_save_data(["position", "area_announced"], true)
		Save.save_game()
		
		area_anouncer_timer.start(TIME_BEFORE_ANNOUNCEMENT)
		await area_anouncer_timer.timeout
		
		area_anouncer.text = TranslationManager.get_translation(AREA_TO_ANNOUNCEMENT[area])
		area_anouncer.show()
		
		area_anouncer_timer.start(ANNOUNCEMENT_TIME)
		SoundController.play_track(AREA_TO_TRACK[area] + "Stinger")
		await area_anouncer_timer.timeout
		area_anouncer.hide()


## Stops any ongoing notifications from the WorldNotifier
func end_notification() -> void:
	world_notifier.stop_displaying()

# ------------------------------------------------------------------------------
# Console commands
# ------------------------------------------------------------------------------
func toggle_level_borders():
	level_borders_enabled = !level_borders_enabled
	Console.print_line("Level borders are now " + ("on" if level_borders_enabled else "off"))


func toggle_indicator_visibility():
	player.indicators_visible = !player.indicators_visible
	player.update_indicator_visibility(false)
	Console.print_line("Indicators are now " + ("visible" if player.indicators_visible else "invisible"))


func zoom_console(factor):
	var ff = float(factor)
	can_zoom = true
	world_camera.enable_limits()
	
	zoom_by(ff, true)
	
	if ff != 1.0:
		can_zoom = false
		world_camera.disable_limits()


func lock_console(x, y):
	if locked_camera_console:
		world_camera.load_state()
	if float(x) == 0 or float(y) == 0:
		locked_camera_console = false
		return
	
	locked_camera_console = true
	world_camera.save_state()
	var pos = Vector2(float(x) * GAME_RESOLUTION[0], float(y) * GAME_RESOLUTION[1])
	world_camera.follow_pos(pos)
"""
