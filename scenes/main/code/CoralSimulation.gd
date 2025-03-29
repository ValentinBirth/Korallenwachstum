extends Object

class_name CoralSimulation

@export var particle_count: int = 1000

var coral_source_id: int

var coral_layer: TileMapLayer = null
var water_layer: TileMapLayer = null
var terrain_layer: TileMapLayer = null
# Dictionaries zur Speicherung der Korallen und Partikel
var cells = {}  # Dictionary: Vector2i -> Coral
var particles = {}  # Dictionary: Vector2i -> 1 (existierende Partikel)
var particleSource = []

var original_cells = {} # Speichert die Startkorallen dauerhaft
# Setup initial coral tiles
func setCells(new_cells):
	cells = new_cells
	original_cells = new_cells.duplicate()
func getCells():
	return cells

func getParticles():
	return particles
	
func setParticleSource(array: Array):
	particleSource = array

# Initialize terrain and coral layers
func set_water_layer(layer: TileMapLayer):
	water_layer = layer

func set_coral_layer(layer: TileMapLayer):
	coral_layer = layer

func set_terrain_layer(layer: TileMapLayer):
	terrain_layer = layer
	
func is_valid_position(pos: Vector2i) -> bool:
	# Calculate the scale ratio between water and coral layers
	var scale_ratio = coral_layer.scale / water_layer.scale  
	
	# Adjust the position to account for scale differences
	#var scaled_pos = pos * Vector2i(scale_ratio)
	var scaled_pos = (Vector2(pos) * scale_ratio).floor()
	var scaled_pos_i = Vector2i(scaled_pos)

	# Check if the position is inside the water area
	var water_id = water_layer.get_cell_source_id(scaled_pos_i)
	print("Tile Position in Water Layer:", scaled_pos_i)
	print("Water ID:", water_layer.get_cell_source_id(scaled_pos_i))
	
	var used_rect = water_layer.get_used_rect()
	if not used_rect.has_point(scaled_pos_i):
		print("Position OUTSIDE valid water area:", scaled_pos_i)
		
	return (
		water_id != -1  # Check if it's water
	)

# Spawn wandering particles randomly around coral
func spawn_particles():
	for source_pos in particleSource:
		if particleSource.size() < particle_count and !particles.has(source_pos):
			particles[source_pos] = 1

func canMove(pos: Vector2i):
	#return pos.x >= -45 and pos.x <= 120 and pos.y >= 85 and pos.y <= 100 and !particles.has(pos)
	return is_valid_position(pos) and !particles.has(pos)
## Calculates Probability of growth at a position
func canGrow(_pos: Vector2i):
	return true
	
# Move particles randomly (with radial growth and branching)
func move_particles():
	var new_particles = {}
	
	spawn_particles()

	for particle_pos in particles.keys():
		var stuck = false  # Flag to track if particle sticks to coral
		
		# Try sticking to coral first
		for offset in get_shuffled_directions():
			var neighbor_pos = particle_pos + offset
			if cells.has(neighbor_pos) and canGrow(particle_pos):  
				cells[particle_pos] = 1  # Particle turns into coral
				stuck = true
				break  # No need to check further directions

		# If the particle didn't stick, attempt movement
		if not stuck:
			var new_pos = particle_pos + get_random_direction()

			# Ensure movement is within bounds and doesn't collide
			if canMove(new_pos):
				new_particles[new_pos] = 1  
			else:
				new_particles[particle_pos] = 1  

	particles = new_particles  # Update particle list

# Helper function to get shuffled movement directions
func get_shuffled_directions() -> Array:
	var directions = [
		Vector2i(0, -1), Vector2i(1, 0),
		Vector2i(-1, 0), Vector2i(0, 1),
		Vector2i(1, 1), Vector2i(1, -1),
		Vector2i(-1, 1), Vector2i(-1, -1)
	]
	directions.shuffle()
	return directions

# Helper function to get a random movement direction
func get_random_direction() -> Vector2i:
	var directions = [
		Vector2i(0, -1), Vector2i(1, 0),
		Vector2i(-1, 0), Vector2i(0, 1),
		Vector2i(1, 1), Vector2i(1, -1),
		Vector2i(-1, 1), Vector2i(-1, -1)
	]
	return directions[randi_range(0, directions.size() - 1)]
func reset():
	print("Resetting coral simulation...")

	particles.clear()

	# originale Korallen wiederherstellen
	cells = original_cells.duplicate()
	
