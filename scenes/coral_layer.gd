extends TileMapLayer

@export var growth_rate: float = 0.05  # Growth interval in seconds

var coral_tiles: Array  
var coral_source_id: int  
var coral_atlas_coord: Vector2i  

func _ready():
	find_existing_coral()
	start_growth_timer()

# Detect existing coral tiles
func find_existing_coral():
	coral_tiles.clear()
	var found_tile = false  

	for pos in get_used_cells():
		var source_id = get_cell_source_id(pos)
		var atlas_coord = get_cell_atlas_coords(pos)

		if source_id != -1:  
			if not found_tile:  
				coral_source_id = source_id
				coral_atlas_coord = atlas_coord
				found_tile = true  
			coral_tiles.append(pos)

	if not found_tile:
		print("Error: No coral tile found on the map!")

# Timer to trigger coral growth
func start_growth_timer():
	var timer = Timer.new()
	timer.wait_time = growth_rate
	timer.timeout.connect(grow_coral)
	add_child(timer)
	timer.start()

# Grow coral using branching bias
func grow_coral():
	if coral_tiles.is_empty():
		return  

	var random_coral = coral_tiles.pick_random()  
	var growth_position = find_growth_position(random_coral)

	if growth_position != Vector2i(-1, -1):  
		set_cell(growth_position, coral_source_id, coral_atlas_coord)  
		coral_tiles.append(growth_position)  
		print("Placing coral at:", growth_position)

# Find a less crowded growth position with branching bias
func find_growth_position(origin: Vector2i) -> Vector2i:
	var directions = [
		Vector2i(0, -1),  # Up (priority)
		Vector2i(1, 0),    # Right
		Vector2i(-1, 0),   # Left
		Vector2i(0, 1)     # Down
	]

	directions.shuffle()  # Shuffle for variety

	var best_position = Vector2i(-1, -1)
	var lowest_neighbors = 999  

	for dir in directions:
		var new_pos = origin + dir

		# Ensure new position is within Y bounds and empty
		if 123 <= new_pos.y and new_pos.y <= 142 and get_cell_source_id(new_pos) == -1:
			var neighbor_count = count_adjacent_coral(new_pos)

			# Pick the position with the fewest neighbors (more space to branch)
			if neighbor_count < lowest_neighbors:
				lowest_neighbors = neighbor_count
				best_position = new_pos

	# Return the best candidate for growth
	return best_position

# Count how many coral tiles are adjacent to a given position
func count_adjacent_coral(pos: Vector2i) -> int:
	var neighbors = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1)
	]
	var count = 0

	for offset in neighbors:
		if (pos + offset) in coral_tiles:
			count += 1

	return count
