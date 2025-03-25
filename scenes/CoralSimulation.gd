extends Object

class_name CoralSimulation
@export var particle_count: int = 100
@export var growth_rate: float = 0.05

var coral_source_id: int
var coral_atlas_coord = Vector2i(23, 5)  # Coral tile atlas coords
#var particle_atlas_coord = Vector2i(0, 0)  # Particle tile atlas coords
var particle_atlas_coord = Vector2i(21, 5)

var terrain_layer: TileMapLayer = null
var coral_layer: TileMapLayer = null
var water_layer: TileMapLayer = null

# Dictionary to store corals
var cells = {}  # Dictionary of Vector2i -> WaterCell
var particles = {}  # Track active particles 

# Setup initial coral tiles
func setCells(new_cells):
	cells = new_cells
	
func getCells():
	return cells

func getParticles():
	return particles

# Initialize terrain, water and coral layers
func set_terrain_layer(layer: TileMapLayer):
	terrain_layer = layer

func set_water_layer(layer: TileMapLayer):
	water_layer = layer
	
func set_coral_layer(layer: TileMapLayer):
	coral_layer = layer

func is_solid(pos: Vector2i) -> bool:
	if water_layer == null:
		return false
	var world_pos = coral_layer.to_global(pos)
	var water_pos = water_layer.to_local(world_pos)
	return water_layer.get_cell_source_id(water_pos) != -1
	
# Spawn wandering particles randomly around coral
func spawn_particles():
	print("Spawning particles...")
	for i in range(particle_count):
		var particle_pos = Vector2i(
			randi_range(-45, 184),  # Random x position
			randi_range(80, 113)    # Random y position
		)
		print("Particle created at: ", particle_pos)  # Ausgabe zur Überprüfung der Position
		particles[particle_pos] = 1

# Move particles randomly (with radial growth and branching)
# Move particles randomly (with radial growth and branching)
func move_particles():
	print("Timer triggered - moving particles...")
	var remaining_particles = []

	# Loop through particle positions
	for particle_pos in particles.keys():  # Use .keys() to avoid modifying while looping
		print("Moving particle at: ", particle_pos)

		var directions = [
			Vector2i(0, -1), Vector2i(1, 0),
			Vector2i(-1, 0), Vector2i(0, 1),
			Vector2i(1, 1), Vector2i(1, -1),
			Vector2i(-1, 1), Vector2i(-1, -1)
		]
		directions.shuffle()

		# Check if the particle touches existing coral
		var stuck = false
		for offset in directions:
			var neighbor_pos = particle_pos + offset
			if cells.has(neighbor_pos):
				# Particle sticks and grows coral
				cells[particle_pos] = 1
				stuck = true
				break

		# If particle didn’t stick, move to a new valid position
		if not stuck:
			var new_pos = particle_pos + directions.pick_random()

			# Ensure new position is valid and unoccupied
			if (
				is_solid(new_pos) 
				#new_pos.x >= -45 and new_pos.x <= 184
				#and new_pos.y >= 80 and new_pos.y <= 113
				and !particles.has(new_pos) # Ensure no particle already there
			):
				remaining_particles.append(new_pos)
			else:
				remaining_particles.append(particle_pos)

	# **Rebuild particles dictionary after loop ends**
	particles.clear()
	for pos in remaining_particles:
		particles[pos] = 1
