extends Object

class_name CoralSimulation

@export var particle_count: int = 100
@export var growth_rate: float = 0.5

var coral_source_id: int

# Dictionaries zur Speicherung der Korallen und Partikel
var cells = {}  # Dictionary: Vector2i -> Coral
var particles = {}  # Dictionary: Vector2i -> 1 (existierende Partikel)
var original_cells = {} # Speichert die Startkorallen dauerhaft
# Setup initial coral tiles
func setCells(new_cells):
	cells = new_cells
	original_cells = new_cells.duplicate()
func getCells():
	return cells

func getParticles():
	return particles

# Spawn wandering particles randomly around coral
func spawn_particles():
	print("Spawning particles...")
	for i in range(particle_count):
		var particle_pos = Vector2i(
			randi_range(5, 90),  # X-Koordinate zwischen 5 und 90
			randi_range(107, 120) # Y-Koordinate knapp über den Korallen
		)
		print("Particle created at: ", particle_pos)  # Ausgabe zur Überprüfung der Position
		particles[particle_pos] = 1
		
func canMove(pos: Vector2i):
	return pos.x >= 5 and pos.x <= 90 and pos.y >= 107 and pos.y <= 120 and !particles.has(pos)
	
# Calculates Probability of growth at a position
func canGrow(pos: Vector2i):
	return true
	
# Move particles randomly (with radial growth and branching)
func move_particles():
	var new_particles = {}

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
	
