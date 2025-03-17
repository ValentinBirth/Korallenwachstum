extends TileMapLayer

@export var particle_count: int = 100
@export var growth_rate: float = 0.05

var coral_source_id: int
var coral_atlas_coord = Vector2i(23, 5)  # Coral tile atlas coords
var particle_atlas_coord = Vector2i(16, 10)

var coral_tiles = []  # Track coral growth
var particles = []  # Track active particles


func _ready():
	setup_coral()
	spawn_particles()


# Setup initial coral tiles
func setup_coral():
	coral_tiles.clear()

	# Scan all tiles and detect the coral's source_id
	for pos in get_used_cells():
		var source_id = get_cell_source_id(pos)
		if source_id != -1:
			if coral_tiles.is_empty():
				coral_source_id = source_id  # Save the first coral tile's source_id
			coral_tiles.append(pos)

	if coral_tiles.is_empty():
		print("No starting coral found!")


# Spawn wandering particles randomly around coral
func spawn_particles():
	print("Spawning particles...")
	for i in range(particle_count):
		var particle_pos = Vector2i(
			randi_range(-11, 100),  # Random x position
			randi_range(93, 113)    # Random y position
		)
		print("Particle created at: ", particle_pos)  # Ausgabe zur Überprüfung der Position
		particles.append(particle_pos)

		# Check if the position is within the valid tilemap range
		if particle_pos.x >= -10 and particle_pos.x <= 100 and particle_pos.y >= 93 and particle_pos.y <= 113:
			set_cell(particle_pos, coral_source_id, particle_atlas_coord)
		else:
			print("Invalid position for particle at: ", particle_pos)

	# Timer to keep particles moving
	var timer = Timer.new()
	timer.wait_time = growth_rate
	timer.one_shot = false  # Ensure the timer repeats
	timer.timeout.connect(move_particles)
	add_child(timer)
	timer.start()


# Move particles randomly
func move_particles():
	print("Timer triggered - moving particles...")
	var remaining_particles = []

	for particle_pos in particles:
		# Random movement directions
		var directions = [
			Vector2i(0, -1), Vector2i(1, 0),
			Vector2i(-1, 0), Vector2i(0, 1)
		]
		directions.shuffle()

		# Check if the particle touches existing coral — not other particles
		var stuck = false
		for offset in directions:
			var neighbor_pos = particle_pos + offset
			if neighbor_pos in coral_tiles:
				set_cell(particle_pos, coral_source_id, coral_atlas_coord)
				coral_tiles.append(particle_pos)
				stuck = true
				break

		# If particle didn’t stick, try moving it
		if not stuck:
			var new_pos = particle_pos + directions.pick_random()

			# Check if new position is within the permitted area
			if (
				new_pos.x >= -10 and new_pos.x <= 100
				and new_pos.y >= 93 and new_pos.y <= 113
				and get_cell_source_id(new_pos) == -1
			):
				erase_cell(particle_pos)
				set_cell(new_pos, coral_source_id, particle_atlas_coord)
				remaining_particles.append(new_pos)
			else:
				remaining_particles.append(particle_pos)

	particles = remaining_particles

	# Respawn particles if needed
	if particles.is_empty():
		print("Coral growth continues!")
		spawn_particles()


# Optional cleanup — stop when coral is big enough
func _process(_delta):
	if coral_tiles.size() > 1000:  # Limit max coral size
		particles.clear()
		print("Coral growth complete!")
