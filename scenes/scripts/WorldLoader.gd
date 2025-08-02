extends Node2D
class_name WorldLoader

signal started_transition(transition_vector)
signal finished_transition
signal finished_transition_process

const BEETLE_SCENE = preload("res://scenes/Beetle.tscn")

const GAME_TIME = 90.0
const GAME_FAKE_TIME = 60.0
const STRESS_TIME = 10.0

# ------------------------------------------------------------------------------
# VARIABLES
# ------------------------------------------------------------------------------
@export var starting_chunk_pos: Vector2i
@export var starting_pos: Vector2

# ------------------------------------------------------------------------------
# NODES
# ------------------------------------------------------------------------------

@onready var view: Sprite2D = $View
@onready var viewport = $Viewport

@onready var world_base: Node2D = $Viewport/WorldBase
@onready var world_camera: Camera2D = $Viewport/WorldCamera
@onready var game_timer: Timer = $GameTimer
@onready var time_label: RichTextLabel = $TimeLabel

@onready var beetle_icon: Sprite2D = $Map/Beetle

var beetle: Beetle


enum CHUNK_STATE {LOADING, LOADED}


const CHUNK_SIZE = Vector2(2560, 2560)
const ROOM_EXTRA_SIZE = Vector2(8, 8)
const PHYSICS_PROCESS_PRIORITY = 1
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
var initialized = false


@onready var map = $Map
@onready var finish_timer: Timer = $FinishTimer


# ------------------------------------------------------------------------------
# BUILT-INS
# ------------------------------------------------------------------------------
func _ready():
	for pin_name in Globals.checked_pins:
		get_node("Map/" + pin_name).frame = 2
	
	SoundController.play_music("Gameplay")
	
	game_timer.start(GAME_TIME)
	
	process_physics_priority = PHYSICS_PROCESS_PRIORITY
	
	GlobalCamera.follow_node(view)
	GlobalCamera.snap_to_aim()
	
	# Load initial chunks
	current_chunk_pos = starting_chunk_pos
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
	
	# Load player
	beetle = BEETLE_SCENE.instantiate()
	world_base.add_child(beetle)
	beetle.position = starting_pos
	beetle.world_camera = world_camera
	beetle.world_loader = self
	
	world_camera.aim_node = beetle.get_node("CameraFollow")
	world_camera.snap_to_aim.call_deferred()


func _physics_process(delta: float) -> void:
	_update_chunk_position()
	_update_queued_chunks()
	#_shift_origin() # TODO: Is this necessary?


func _process(delta: float) -> void:
	var time_progress = pow((GAME_TIME - game_timer.time_left) / GAME_TIME, 0.9)
	var fake_time_left = GAME_FAKE_TIME - time_progress * GAME_FAKE_TIME
	if fake_time_left > STRESS_TIME:
		time_label.text = "[center]%d" % [int(fake_time_left)]
	else:
		time_label.text = "[center]%.2f" % [fake_time_left]
	
	beetle_icon.position = Vector2(960.0 / 19200.0 * beetle.position[0], 540.0 / 7900.0 * beetle.position[1]) + Vector2(-15, 120)
	beetle_icon.position[0] = max(-850, beetle_icon.position[0])
	beetle_icon.position[0] = min(850, beetle_icon.position[0])
	beetle_icon.position[1] = max(-425, beetle_icon.position[1])
	beetle_icon.position[1] = min(425, beetle_icon.position[1])


## Checks if player has moved out of current chunk. If so, unloads old chunks
## and queues loading of old ones
func _update_chunk_position():
	# Get player's local chunk
	var local_chunk = get_chunk_position(beetle.position)
	
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
	if chunk_shift == Vector2i(0, 0) or not (beetle.has_dung or beetle.dung.landed) or beetle.is_grounded:
		return
	print("Shifted origin from %s to %s" % [current_chunk_pos - chunk_shift, current_chunk_pos])
	
	# Shifting origin
	var adjustment_vector = -Vector2(chunk_shift) * CHUNK_SIZE
	for child in world_base.get_children():
		child.position += adjustment_vector
	world_camera.adjust(adjustment_vector)
	beetle.adjust(adjustment_vector)
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


func get_chunk_position(pos: Vector2):
	return Vector2i(floor((pos[0] - fposmod(pos[0], CHUNK_SIZE[0])) / CHUNK_SIZE[0]), floor((pos[1] - fposmod(pos[1], CHUNK_SIZE[1])) / CHUNK_SIZE[1]))


func add_chunk(chunk_pos: Vector2i, chunk: Chunk):
	chunk.position = Vector2(chunk_shift + chunk_pos - current_chunk_pos) * CHUNK_SIZE
	world_base.add_child(chunk)


## Returns the path for the chunk in the specified position, or null if there is
## no chunk
func get_chunk_path(chunk_pos: Vector2i):
	var path = "res://scenes/chunks/" + str(chunk_pos[0]) + "_" + str(chunk_pos[1]) + ".tscn"
	if ResourceLoader.exists(path):
		return path
	return null


## Asks for a reset of the current level
func queue_reset():
	if not game_timer.is_stopped():
		SoundController.mute_music()
	
	SceneManager.goto_scene("res://scenes/ResetCutscene.tscn")


func check_pin(pin_name):
	Globals.check_pin(pin_name)
	get_node("Map/" + pin_name).frame = 2


func open_map():
	map.show()


func close_map():
	map.hide()


func finish():
	finish_timer.timeout.connect(SceneManager.goto_scene.bind("res://scenes/EndCutscene.tscn"))
	finish_timer.start(5.0)
