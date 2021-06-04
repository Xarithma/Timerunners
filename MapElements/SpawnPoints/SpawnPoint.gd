extends Position2D

export var opening: String = "Left"


# When the position gets initialised.
func _ready() -> void:
	# If there is already a spawned chunk, don't run further
	if Globals.chunk_positions.has(global_position):
		queue_free()
		return

	# Add the chunk to the array
	Globals.chunk_positions.append(global_position)

	# Spawn a room according to the point opening
	match opening:
		"Up":
			Globals.spawn_chunk(Globals.up_chunks, global_position)
		"Down":
			Globals.spawn_chunk(Globals.down_chunks, global_position)
		"Left":
			Globals.spawn_chunk(Globals.left_chunks, global_position)
		"Right":
			Globals.spawn_chunk(Globals.right_chunks, global_position)

	queue_free()
