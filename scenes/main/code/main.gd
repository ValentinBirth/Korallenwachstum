extends Node2D

class_name MainSimulation

# Importiere das DiffusionLogic-Script
@export var water_simulation_script: Script

# TileMap-Referenzen
@onready var water_layer: TileMapLayer = $layer_holder/WaterLayer

# Wassersimulations-Instanz
var water_simulation

# Konstanten für das Grid
const GRID_WIDTH: int = 50
const GRID_HEIGHT: int = 30

# Zeitsteuerung
var step_time: float = 0.05
var time_since_last_step: float = 0.0

var border_color = Color(0.0, 0.0, 0.0)
var grid_updated = false

func _ready():
	water_simulation = water_simulation_script.new(GRID_WIDTH, GRID_HEIGHT)
	update_layers()
	mark_grid_as_updated()
	update_border_tiles()

func _process(delta: float):
	handle_water_placement()
	time_since_last_step += delta
	if time_since_last_step >= step_time:
		# Diffusion aktualisieren
		water_simulation.update_simulation()

		# Darstellung aktualisieren
		update_layers()
		
		if grid_updated:
			update_border_tiles()  # This will trigger the redraw of the outer border
			grid_updated = false  # Reset the flag after drawin
		# Zeitsteuerung zurücksetzen
		time_since_last_step = 0.0
		
func update_border_tiles():
	# Set the border tiles on the grid
	var border_tile_id = Vector2i(4,0)
	for x in range(GRID_WIDTH):
		# Top row
		water_layer.set_cell(Vector2i(x, -1), 1, border_tile_id)
		# Bottom row
		water_layer.set_cell(Vector2i(x, GRID_HEIGHT),1 , border_tile_id)
	
	for y in range(GRID_HEIGHT+2):
		# Left column
		water_layer.set_cell(Vector2i(-1, y-1),1 , border_tile_id)
		# Right column
		water_layer.set_cell(Vector2i(GRID_WIDTH, y-1),1 , border_tile_id)
	
func mark_grid_as_updated():
	grid_updated = true

func update_layers():
	var water_grid = water_simulation.get_water_grid()
	var salt_grid = water_simulation.get_salt_grid()

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			# Setze die Tiles je nach Wasser- und Salzstand
			var tile_vector = get_tile_id_for_value(water_grid[y][x], salt_grid[y][x])
			water_layer.set_cell(Vector2i(x,y),1,tile_vector)

# Bestimme das passende Tile aus dem TileSet basierend auf den Werten von Wasser und Salz
func get_tile_id_for_value(water_value: float, salt_value: float) -> Vector2i:

	var salt_level: int
	salt_level = int(clamp(salt_value * 5, 0, 4))
	var water_level: int
	water_level = int(clamp(water_value * 5, 0, 4))
	if water_level == 0:
		return Vector2i(0,1)
	if salt_level >0:
		return Vector2i(1,water_level+salt_level*4)
	else:
		return Vector2i(1,water_level)
		
func world_to_tile(world_pos: Vector2) -> Vector2i:
		return water_layer.local_to_map(world_pos)
		
func is_within_bounds(tile_coords: Vector2i) -> bool:
	return tile_coords.x >= 0 and tile_coords.x < GRID_WIDTH-1 and \
		tile_coords.y >= 0 and tile_coords.y < GRID_HEIGHT-1	
		
func handle_water_placement():
	if Input.is_action_just_pressed("left_click"):
		var tile_coords = world_to_tile(get_global_mouse_position())
		if is_within_bounds(tile_coords):
			water_simulation.set_water(tile_coords,1)
	if Input.is_action_just_pressed("right_click"):
		var tile_coords = world_to_tile(get_global_mouse_position())
		if is_within_bounds(tile_coords):
			water_simulation.set_salt(tile_coords,1)
			water_simulation.set_water(tile_coords,1)
