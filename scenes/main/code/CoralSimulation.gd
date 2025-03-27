extends Object

class_name CoralSimulation

@export var particle_count: int = 100
@export var growth_rate: float = 0.05

var coral_source_id: int
var coral_atlas_coord = Vector2i(23, 5)  # Coral tile atlas coords
var particle_atlas_coord = Vector2i(21, 5)  # Particle tile atlas coords

# Dictionaries zur Speicherung der Korallen und Partikel
var cells = {}  # Dictionary: Vector2i -> Coral
var particles = {}  # Dictionary: Vector2i -> 1 (existierende Partikel)

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
			randi_range(5, 90),  # X-Koordinate zwischen 5 und 90
			randi_range(107, 120) # Y-Koordinate knapp über den Korallen
		)
		print("Particle created at: ", particle_pos)  # Ausgabe zur Überprüfung der Position
		particles[particle_pos] = 1

# Move particles randomly (with radial growth and branching)
func move_particles():
	print("Timer triggered - moving particles...")
	var remaining_particles = {}

	for particle_pos in particles.keys():  # Iteriere über bestehende Partikel
		print("Moving particle at: ", particle_pos)

		var directions = [
			Vector2i(0, -1), Vector2i(1, 0),
			Vector2i(-1, 0), Vector2i(0, 1),
			Vector2i(1, 1), Vector2i(1, -1),
			Vector2i(-1, 1), Vector2i(-1, -1)
		]
		directions.shuffle()

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
				new_pos.x >= 5 and new_pos.x <= 90
				and new_pos.y >= 107 and new_pos.y <= 120
				and !particles.has(new_pos)  # Keine Überschneidung mit anderen Partikeln
			):
				remaining_particles[new_pos] = 1  # Partikel bewegt sich
			else:
				remaining_particles[particle_pos] = 1  # Falls keine Bewegung möglich, bleibt es stehen

	particles = remaining_particles  # Aktualisiere Partikel-Liste
