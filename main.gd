extends Node2D

class_name MainSimulation

# Importiere das DiffusionLogic-Script
@export var diffusion_logic_script: Script

# TileMap-Referenzen
@onready var water_layer: TileMapLayer = $layer_holder/WaterLayer

# Diffusionslogik-Instanz
var diffusion_logic

# Konstanten für das Grid
const GRID_WIDTH: int = 50
const GRID_HEIGHT: int = 30

# Zeitsteuerung
var step_time: float = 0.1
var time_since_last_step: float = 0.0

func _ready():
	# Lade die Diffusionslogik dynamisch
	diffusion_logic = diffusion_logic_script.new(GRID_WIDTH, GRID_HEIGHT)
	diffusion_logic.randomize_grids()

	# Initiale Darstellung
	update_layers()

func _process(delta: float):
	time_since_last_step += delta
	if time_since_last_step >= step_time:
		# Diffusion aktualisieren
		diffusion_logic.update_diffusion()

		# Darstellung aktualisieren
		update_layers()

		# Zeitsteuerung zurücksetzen
		time_since_last_step = 0.0

func update_layers():
	var water_grid = diffusion_logic.get_water_grid()
	var salt_grid = diffusion_logic.get_salt_grid()

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			# Setze die Tiles je nach Wasser- und Salzstand
			var tile_vector = get_tile_id_for_value(water_grid[y][x], salt_grid[y][x])
			water_layer.set_cell(Vector2i(x,y),0,tile_vector)

# Bestimme das passende Tile aus dem TileSet basierend auf den Werten von Wasser und Salz
func get_tile_id_for_value(water_value: float, salt_value: float) -> Vector2i:
	# Beispiel für einfache Wertezuordnung#
	var salt_level: int
	salt_level = int(clamp(salt_value * 5, 1, 5))
	var water_level: int
	water_level = int(clamp(water_value * 5, 1, 5))
	if water_level == 0:
		return Vector2i(1,0)
	if salt_level >=0:
		return Vector2i(0,salt_level)
	else:
		return Vector2i(1,water_level)
