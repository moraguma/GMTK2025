@tool
extends Node2D
class_name WorldCreator


const BASE_LAYER = 0

const CELL_SIZE = 64

const CHUNK_SIZE = Vector2(2560, 2560)
const TILE_LAYER = 0


@export var world_min: Vector2
@export var world_max: Vector2


var tilemaps_to_scenes: Dictionary
var last_time: float
var just_compiled = false


func _enter_tree() -> void:
	tilemaps_to_scenes = {
		$Tilemaps/Tiles: preload("res://scenes/Tiles.tscn"),
	}


func _process(delta):
	if Input.is_key_pressed(KEY_C) and Input.is_key_pressed(KEY_ALT):
		if not just_compiled:
			compile()
			just_compiled = true
	else:
		just_compiled = false


func _get_tool_buttons():
	return ["compile"]


func compile():
	var starting_time = Time.get_ticks_msec()
	last_time = starting_time
	print("----- Starting compilation -----")
	
	# Find world borders
	await show_progress("Finished finding world borders")
	
	# Define chunk positions
	var min_chunk = get_chunk_position(world_min)
	var max_chunk = get_chunk_position(world_max)
	var chunk_data = generate_chunk_data(world_min, world_max)
	await show_progress("Finished defining world positions")
	
	# Populate chunk info
	var chunk_info = check_for_chunk_tilemaps(chunk_data)
	var uses_tilemap = chunk_info[0]
	var has_content = chunk_info[1]
	await show_progress("Finished checking tilemaps")
	
	# Create all chunks as well as their tiles
	var chunks = create_chunks(chunk_data, uses_tilemap)
	await show_progress("Finished creating chunks")
	
	# Creates chunk elements - assumes elements belong to one chunk only
	var elements = $Elements.get_children()
	add_elements_to_chunks(chunk_data, chunks, has_content, elements)
	await show_progress("Finished adding chunk elements")
	
	# Saves chunks
	save_chunks(chunks, chunk_data, has_content)
	await show_progress("Finished saving chunks")
	
	print("----- Finished compilation in %ss -----" % [(Time.get_ticks_msec() - starting_time) / 1000.0]) 


func show_progress(message: String):
	var time = (Time.get_ticks_msec() - last_time) / 1000.0
	var best_time = -999.0
	var color = Color("#ffffff")
	
	print_rich(message + " - [color=#%s]%ss" % [color.to_html(false), time])
	await get_tree().process_frame
	last_time = Time.get_ticks_msec()


#region Utils
## Given a list of polygons and a polygon, merges this polygon with as many
## polygons from the list it can, deleting them from the list in the process.
## Adds the merge result to the end of the list
func merge_or_append_polygon(polygons: Array, holes: Array, polygon: PackedVector2Array):
	var i = 0
	while i < len(polygons):
		var merge = Geometry2D.merge_polygons(polygons[i], polygon)
		if len(merge) == 1:
			polygon = merge[0]
			polygons.pop_at(i)
			i = 0
		elif len(merge) > 1:
			var internal = false
			for p in merge:
				if Geometry2D.is_polygon_clockwise(p):
					internal = true
					break
			
			if internal:
				polygons.pop_at(i)
				for p in merge:
					if not Geometry2D.is_polygon_clockwise(p):
						polygon = p
						break
			else:
				i += 1
		else:
			i += 1
	
	polygons.append(polygon)


func get_chunk_path(chunk_pos: Vector2i):
	return "res://scenes/chunks/%s.tscn" % [str(chunk_pos[0]) + "_" + str(chunk_pos[1])]


func prepare_for_saving(node: Node, owner: Node):
	node.owner = owner
	
	if node.scene_file_path == "":
		for child in node.get_children():
			prepare_for_saving(child, owner)


func add_child_and_owner(parent: Node, child: Node):
	var past_owner = parent.owner
	var new_owner = parent
	while not past_owner == null:
		new_owner = past_owner
		past_owner = past_owner.owner
	
	parent.add_child(child)
	child.owner = new_owner


func add_to_border_dict(border_dict: Dictionary, border: float, value):
	if not border in border_dict:
		border_dict[border] = []
	
	border_dict[border].append(value)


## Returns the chunk coordinate of this position
func get_chunk_position(pos: Vector2):
	return Vector2i(floor((pos[0] - fposmod(pos[0], CHUNK_SIZE[0])) / CHUNK_SIZE[0]), floor((pos[1] - fposmod(pos[1], CHUNK_SIZE[1])) / CHUNK_SIZE[1]))



func is_position_inside_chunk(chunk_pos: Vector2i, pos):
	return is_position_inside_rect(Rect2(Vector2(chunk_pos) * CHUNK_SIZE, CHUNK_SIZE), pos)


func is_position_inside_rect(rect: Rect2, pos: Vector2):
	return pos[0] >= rect.position[0] and pos[0] < rect.position[0] + rect.size[0] and \
				pos[1] >= rect.position[1] and pos[1] < rect.position[1] + rect.size[1]
#endregion

#region Chunks
## Defines all chunks and their sizes
func generate_chunk_data(world_min: Vector2, world_max: Vector2):
	var chunk_data: Dictionary = {}
	var min_chunk = get_chunk_position(world_min)
	var max_chunk = get_chunk_position(world_max)
	for chunk_i in range(min_chunk[0], max_chunk[0] + 1):
		for chunk_j in range(min_chunk[1], max_chunk[1] + 1):
			chunk_data[Vector2i(chunk_i, chunk_j)] =  Rect2(Vector2(chunk_i * CHUNK_SIZE[0], chunk_j * CHUNK_SIZE[1]), CHUNK_SIZE)
	return chunk_data


## Check where each tilemap is active. uses_tilemaps stores the active state
## of each tilemap for each level delimiter
func check_for_chunk_tilemaps(chunk_data: Dictionary):
	var uses_tilemap: Dictionary = {}
	var has_content: Dictionary = {}
	for chunk_pos in chunk_data:
		has_content[chunk_pos] = false
		var chunk_rect: Rect2 = chunk_data[chunk_pos]
		uses_tilemap[chunk_pos] = {}
		
		for tilemap: TileMap in tilemaps_to_scenes:
			var done = false
			var x = chunk_rect.position[0] / CELL_SIZE
			while x < (chunk_rect.position[0] + chunk_rect.size[0]) / CELL_SIZE and not done:
				var y = chunk_rect.position[1] / CELL_SIZE
				while y < (chunk_rect.position[1] + chunk_rect.size[1]) / CELL_SIZE and not done:
					done = tilemap.get_cell_source_id(TILE_LAYER, Vector2i(x, y)) != -1
					y += 1
				x += 1
			uses_tilemap[chunk_pos][tilemap] = done
			if uses_tilemap[chunk_pos][tilemap]:
				has_content[chunk_pos] = true
	return [uses_tilemap, has_content]


## Creates all chunks as well as their tiles
func create_chunks(chunk_data: Dictionary, uses_tilemap: Dictionary):
	var chunks: Dictionary = {}
	for chunk_pos in chunk_data:
		var chunk_rect: Rect2 = chunk_data[chunk_pos]
		var new_chunk = Chunk.new()
		new_chunk.name = str(chunk_pos)
		for tilemap: TileMap in uses_tilemap[chunk_pos]:
			if uses_tilemap[chunk_pos][tilemap]:
				var new_tilemap: TileMap = tilemaps_to_scenes[tilemap].instantiate()
				var difference = Vector2i(-chunk_rect.position[0] / CELL_SIZE, -chunk_rect.position[1] / CELL_SIZE)
				
				for layer in range(tilemap.get_layers_count()):
					new_tilemap.set_layer_z_index(layer, tilemap.get_layer_z_index(layer))
					for x in range(chunk_rect.position[0] / CELL_SIZE, (chunk_rect.position[0] + chunk_rect.size[0]) / CELL_SIZE):
						for y in range(chunk_rect.position[1] / CELL_SIZE, (chunk_rect.position[1] + chunk_rect.size[1]) / CELL_SIZE):
							var cell = Vector2i(x, y)
							var source_id = tilemap.get_cell_source_id(layer, cell)
							
							if source_id != -1:
								new_tilemap.set_cell(layer, cell + difference, source_id, tilemap.get_cell_atlas_coords(layer, cell))
				
				add_child_and_owner(new_chunk, new_tilemap)
		
		chunks[chunk_pos] = new_chunk
	return chunks


## Adds elements to chunks
func add_elements_to_chunks(chunk_data, chunks, has_content, elements):
	for element in elements:
		var chunk_pos = get_chunk_position(element.position)
		var chunk = chunks[chunk_pos]
		var chunk_rect = chunk_data[chunk_pos]
		has_content[chunk_pos] = true
		
		var new_node = element.duplicate(7)
		new_node.position -= chunk_rect.position
		chunk.add_child(new_node)
		prepare_for_saving(new_node, chunk)


## Saves chunks
func save_chunks(chunks, chunk_data, has_content):
	for chunk_pos in chunk_data:
		if has_content[chunk_pos]:
			var scene = PackedScene.new()
			scene.pack(chunks[chunk_pos])
			ResourceSaver.save(scene, get_chunk_path(chunk_pos))
#endregion
