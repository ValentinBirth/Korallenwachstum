extends Node2D

class_name MainSimulation

# Importiere das WaterSimulation-Script
@export var water_simulation_script: Script
@onready var water_layer: TileMapLayer = $layer_holder/WaterLayer
@onready var terrain_layer: TileMapLayer = $layer_holder/TerrainLayer

var water_simulation
var step_time: float = 0.05
var time_since_last_step: float = 0.0

# Configuration parameters
@export var debug_mode: bool = false
@export var water_amount: float = 1.0
@export var salt_amount: float = 1.0

# Source and drain parameters
@export var source_water_rate: float = 1
@export var source_salt_concentration: float = 0.0
@export var drain_rate: float = 0.5

# Hardcoded source and drain positions
@export var source_positions: Array[Vector2i] = [
	Vector2i(14,7)
]

@export var drain_positions: Array[Vector2i] = [
	Vector2i(-64,19)
]

func _ready():
	# Initialize the water simulation
	water_simulation = water_simulation_script.new()
	water_simulation.set_terrain_layer(terrain_layer)
	water_simulation.debug_mode = debug_mode
	
	# Set up sources and drains
	water_simulation.setup_sources(source_positions, source_water_rate, source_salt_concentration)
	water_simulation.setup_drains(drain_positions, drain_rate)
	
	# Initial rendering update
	update_layers()

func _process(delta: float):
	# Handle input separately from simulation
	handle_water_placement()
	
	# Update physics at fixed timestep
	time_since_last_step += delta
	if time_since_last_step >= step_time:
		water_simulation.update_simulation()
		time_since_last_step = 0.0
	
	# Always update rendering
	update_layers()

func update_layers():
	# Clear water layer before redrawing
	water_layer.clear()
	
	# Get current water and salt data
	var water_grid = water_simulation.get_water_grid()
	var salt_grid = water_simulation.get_salt_grid()

	# Update visual representation for each cell with water
	for cell in water_grid.keys():
		var tile_vector = get_tile_id_for_value(water_grid[cell], salt_grid.get(cell, 0))
		water_layer.set_cell(cell, 1, tile_vector)

func get_tile_id_for_value(water_value: float, salt_value: float) -> Vector2i:
	# Calculate visual representation based on water and salt values
	var salt_level: int = int(clamp(salt_value * 5, 0, 4))
	var water_level: int = int(clamp(water_value * 5, 0, 4))
	
	if water_level == 0:
		return Vector2i(0, 1)
	if salt_level > 0:
		return Vector2i(1, water_level + salt_level * 4)
	else:
		return Vector2i(1, water_level)

func world_to_tile(world_pos: Vector2) -> Vector2i:
	# Convert world coordinates to tile coordinates
	return water_layer.local_to_map(world_pos)

func handle_water_placement():
	# Handle adding water with left mouse button
	if Input.is_action_just_pressed("left_click"):
		var tile_coords = world_to_tile(get_global_mouse_position())
		water_simulation.set_water(tile_coords, water_amount)
	
	# Handle adding salt water with right mouse button
	if Input.is_action_just_pressed("right_click"):
		var tile_coords = world_to_tile(get_global_mouse_position())
		water_simulation.set_salt(tile_coords, salt_amount)
		water_simulation.set_water(tile_coords, water_amount)
