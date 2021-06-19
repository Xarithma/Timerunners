extends Node

# -> Chunk sorted by openings
var left_chunks: Array = []
var right_chunks: Array = []
var up_chunks: Array = []
var down_chunks: Array = []

# -> Stored chunk positions to prevent faulty spawns
var chunk_positions: Array = [Vector2.ZERO]

# -> Map backgrounds
var backgrounds: Array = []


func _ready() -> void:
	# -> Setting multiplayer seed
	seed(Globals.game_seed)

	# -> Initialize game nodes and assets
	_init_files("res://source/Game/MapGeneration/")
	_init_files("res://assets/Backgrounds/Maps/")


func _init_files(path: String) -> void:
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			if file.ends_with(".png"):
				# -> Load backgrounds
				backgrounds.append(path + file)
			else:
				# -> Load chunks
				if "Up" in file:
					up_chunks.append(path + file)
				if "Down" in file:
					down_chunks.append(path + file)
				if "Left" in file:
					left_chunks.append(path + file)
				if "Right" in file:
					right_chunks.append(path + file)

	dir.list_dir_end()


func spawn_chunk(point: Position2D) -> void:
	# -> Point checking
	if chunk_positions.has(point.global_position):
		point.queue_free()
		return
	
	# -> Add point to checks
	chunk_positions.append(point.global_position)

	# -> Temporary array
	var arr: Array

	# -> Select which array is suitable
	match point.name:
		"Up":
			arr = down_chunks
		"Down":
			arr = up_chunks
		"Left":
			arr = right_chunks
		"Right":
			arr = left_chunks

	# -> Instancing and spawning chunk
	var chunk_instance = arr[randi() % arr.size()].instance()
	add_child(chunk_instance)

	# -> Set chunk position
	chunk_instance.global_position = point.global_position
