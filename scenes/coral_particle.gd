extends TileMapLayer

@export var growth_rate: float = 0.05  # Growth speed
@export var walker_count: int = 5  # Number of particles/walkers
@export var max_walkers: int = 500  # Safety limit for particles
@export var spawn_radius: int = 10  # Distance from coral to spawn walkers
@export var particle_scene: PackedScene  # Link the CoralParticle scene


var coral_tiles: Array  
var coral_source_id: int  
var coral_atlas_coord: Vector2i  

var walkers: Array  # List of active particles

func _ready():
	find_existing_coral()
	start_growth_timer()

# Find existing coral tiles and detect tile ID
func find_existing_coral():
	coral_tiles.clear()
	for pos in get_used_cells():
		var source_id = get_cell_source_id(pos)
		var atlas_coord = get_cell_atlas_coords(pos)

		if source_id != -1:
			coral_source_id = source_id
			coral_atlas_coord = atlas_coord
			coral_tiles.append(pos)

	if coral_tiles.is_empty():
		print("Error: No coral tiles found!")

# Timer to trigger coral growth
func start_growth_timer():
	var timer = Timer.new()
	timer.wait_time = growth_rate
	timer.timeout.connect(spawn_walkers)
	add_child(timer)
	timer.start()

# Spawn particles around the coral
func spawn_walkers():
	while walkers.size() < walker_count and walkers.size() < max_walkers:
		var start_pos = pick_random_spawn_point()
		
		# Create a new particle at the starting position
		var particle = particle_scene.instantiate()
		particle.position = map_to_local(start_pos)
		add_child(particle)

		# Track the particle as a walker
		walkers.append({"pos": start_pos, "particle": particle})

# Choose a random starting point around coral within a radius
func pick_random_spawn_point() -> Vector2i:
	var coral_center = coral_tiles.pick_random()
	var random_offset = Vector2i(
		randi_range(-spawn_radius, spawn_radius),
		randi_range(-spawn_radius, spawn_radius)
	)
	return coral_center + random_offset

# Move all walkers randomly
func move_walkers():
	var new_walkers = []
	for walker_data in walkers:
		var walker = walker_data["pos"]
		var particle = walker_data["particle"]
		var new_pos = walker + pick_random_direction()

		# Move the particle visually
		particle.position = map_to_local(new_pos)

		# If walker touches coral, convert to a coral tile and remove particle
		if is_touching_coral(new_pos):
			set_cell(new_pos, coral_source_id, coral_atlas_coord)
			coral_tiles.append(new_pos)
			particle.queue_free()
			print("New coral added at:", new_pos)

		# If it didn't stick, keep the walker moving
		elif 123 <= new_pos.y <= 142 and get_cell_source_id(new_pos) == -1:
			new_walkers.append({"pos": new_pos, "particle": particle})
		else:
			particle.queue_free()  # If the walker hits a wall, remove it

	# Keep only the walkers that haven't stuck or died
	walkers = new_walkers

# Pick a random direction (4 directions)
func pick_random_direction() -> Vector2i:
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	return directions[randi() % directions.size()]

# Check if a walker is adjacent to coral
func is_touching_coral(pos: Vector2i) -> bool:
	var neighbors = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1)
	]
	for dir in neighbors:
		if (pos + dir) in coral_tiles:
			return true
	return false
