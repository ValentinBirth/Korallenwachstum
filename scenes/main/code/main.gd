extends Node2D

class_name MainSimulation

# Importiere das WaterSimulation-Script
@export var water_simulation_script: Script
@export var coral_simulation_script: Script
@onready var water_layer: TileMapLayer = $layer_holder/WaterLayer
@onready var terrain_layer: TileMapLayer = $layer_holder/TerrainLayer
@onready var coral_layer: TileMapLayer = $layer_holder/CoralLayer

@onready var Salt_slider: VSlider = $"Salt Regulator"
@onready var FillSalt_slider: VSlider = $"FillSaltRegulator"

var water_simulation: WaterSimulation
var coral_simulation: CoralSimulation
var step_time: float = 0.01
var time_since_last_step: float = 0.05

# Configuration parameters
@export var debug_mode: bool = true
@export var water_amount: float = 1.0
@export var salt_amount: float = 1.0

# Source and drain parameters
@export var source_water_rate: float = 0.5
@export var source_salt_concentration: float = 0.0
@export var drain_rate: float = 1

# Hardcoded source and drain positions
@export var source_positions: Array[Vector2i] = [
	Vector2i(14,1),
	Vector2i(14,2),
	Vector2i(14,3),
	Vector2i(14,4)
]

@export var particle_source_positions: Array[Vector2i] = [
	Vector2i(-110,63)
]

@export var drain_positions: Array[Vector2i] = [
	Vector2i(-64,1),
	Vector2i(-64,2),
	Vector2i(-64,3),
	Vector2i(-64,4)
]
func findCoralCells():
	var corals = {}
	# Scan all tiles and detect the coral's source_id
	for pos in coral_layer.get_used_cells():
		var source_id = coral_layer.get_cell_source_id(pos)
		if source_id != -1:
			corals[pos] = 1
	return corals

func _ready():
	# Initialize the water simulation
	water_simulation = water_simulation_script.new()
	water_simulation.set_water_layer(water_layer)
	water_simulation.set_terrain_layer(terrain_layer)
	water_simulation.debug_mode = debug_mode
	
	# Set up sources and drains
	water_simulation.setup_sources(source_positions, source_water_rate, source_salt_concentration)
	water_simulation.setup_drains(drain_positions, drain_rate)
	water_simulation.fill_pool(0)
	
	# Initial rendering update
	coral_simulation = coral_simulation_script.new()
	coral_simulation.set_coral_layer(coral_layer)
	coral_simulation.set_water_layer(water_layer)
	coral_simulation.setParticleSource(particle_source_positions)
	coral_simulation.setCells(findCoralCells())
	coral_simulation.spawn_particles()
	
	
	update_layers()

func _process(delta: float):
	# Handle input separately from simulation
	handle_water_placement()
	
	update_sources()
	
	# Update physics at fixed timestep
	time_since_last_step += delta
	if time_since_last_step >= step_time:
		water_simulation.update_simulation()
		coral_simulation.move_particles()
		time_since_last_step = 0.0
	
	# Always update rendering
	update_layers()

func update_layers():
	# Clear water layer before redrawing
	water_layer.clear()
	
	# Get current water and salt data
	var water_grid = water_simulation.get_water_grid()

	# Update visual representation for each cell with water
	for cell in water_grid.keys():
		var tile_vector = get_tile_id_for_value(water_grid[cell])
		water_layer.set_cell(cell, 1, tile_vector)
		
	coral_layer.clear()
	
	var corals = coral_simulation.getCells()
	var particles = coral_simulation.getParticles()
	
	for coral in corals.keys():
		coral_layer.set_cell(coral,0,Vector2i(21,5))
		
	for particle in particles.keys():
		#coral_layer.set_cell(particle,0,Vector2i(3,16))
		coral_layer.set_cell(particle,0,Vector2i(11,11))


func get_tile_id_for_value(water_cell: WaterSimulation.WaterCell) -> Vector2i:
	# Calculate visual representation based on water and salt values
	var salt_level: int = int(clamp(water_cell.salt_amount * 5, 0, 4))
	var water_level: int = int(clamp(water_cell.water_amount * 5, 0, 4))
	
	if water_level == 0:
		return Vector2i(0, 1)
	if salt_level > 0:
		return Vector2i(1, water_level + salt_level * 4)
	else:
		return Vector2i(1, water_level)

func handle_water_placement():
	# Handle adding water with left mouse button
	if Input.is_action_just_pressed("left_click"):
		var tile_coords = water_layer.local_to_map(water_layer.to_local(get_global_mouse_position()))
		water_simulation.set_water(tile_coords, water_amount,0)
	
	# Handle adding salt water with right mouse button
	if Input.is_action_just_pressed("right_click"):
		var tile_coords = water_layer.local_to_map(water_layer.to_local(get_global_mouse_position()))
		water_simulation.set_water(tile_coords, water_amount, salt_amount)
		
func update_sources():
	var sources = water_simulation.get_source_positions()
	for source in sources:
		source.salt_concentration = Salt_slider.value

func _on_fill_pool_button_pressed() -> void:
	var salt_value = FillSalt_slider.value  
	water_simulation.fill_pool(salt_value)  
	update_layers()

func _on_clear_pool_button_pressed() -> void:
	water_simulation.clear_pool()

func _on_coral_reset_button_pressed() -> void:
	coral_simulation.reset()
	update_layers()
