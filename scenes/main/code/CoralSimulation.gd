extends Object

class_name CoralSimulation
@export var particle_count: int = 100
@export var growth_rate: float = 0.05

var coral_source_id: int
var coral_atlas_coord = Vector2i(23, 5)  # Coral tile atlas coords
#var particle_atlas_coord = Vector2i(0, 0)  # Particle tile atlas coords
var particle_atlas_coord = Vector2i(21, 5)

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
	
# Spawn wandering particles randomly around coral
func spawn_particles():
	print("Spawning particles...")
	for i in range(particle_count):
		var particle_pos = Vector2i(
			randi_range(-253, -26),  # Random x position
			randi_range(50, 70)    # Random y position
		)
		print("Particle created at: ", particle_pos)  # Ausgabe zur Überprüfung der Position
		particles[particle_pos] = 1

# Move particles randomly (with radial growth and branching)
func move_particles():
	print("Timer triggered - moving particles...")
	var remaining_particles = []

	# Radial movement: particles will spread out from the origin
	for particle_pos in particles:
		print("Moving particle at: ", particle_pos)  # Ausgabe, um Positionen der Partikel zu prüfen
		# Determine the direction of growth (radially outwards)
		var directions = [
			Vector2i(0, -1), Vector2i(1, 0),
			Vector2i(-1, 0), Vector2i(0, 1),
			Vector2i(1, 1), Vector2i(1, -1),
			Vector2i(-1, 1), Vector2i(-1, -1)
		]
		directions.shuffle()

		# Check if the particle touches existing coral — not other particles
		var stuck = false
		for offset in directions:
			var neighbor_pos = particle_pos + offset
			if cells.has(neighbor_pos):
				# If particle touches coral, it sticks and adds a new growth point
				particles.erase(particle_pos)
				cells[particle_pos] = 1
				stuck = true
				break

		# If particle didn’t stick, try moving it to an empty spot near coral
		if not stuck:
			var new_pos = particle_pos + directions.pick_random()

			# Check if new position is within the permitted area and no particle exists there
			if (
				new_pos.x >= -10 and new_pos.x <= 100
				and new_pos.y >= 93 and new_pos.y <= 113
				and !particles.has(new_pos) # Make sure it's empty
			):
				particles.erase(particle_pos)
				remaining_particles.append(new_pos)
			else:
				remaining_particles.append(particle_pos)


	var new_particles = {}  
	for pos in remaining_particles:
		new_particles[pos] = 1  # Oder eine sinnvolle Zahl

	particles = new_particles
