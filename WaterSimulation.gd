extends Object

class_name WaterSimulation

var GRID_WIDTH: int
var GRID_HEIGHT: int
const MAX_WATER: float = 1.0
const DIFFUSION_RATE: float = 0.25

var grid: Array
var next_grid: Array
var salt_grid: Array
var next_salt_grid: Array

func _init(width: int, height: int):
	GRID_WIDTH = width
	GRID_HEIGHT = height
	_initialize_grids()

func _initialize_grids():
	for _y in range(GRID_HEIGHT):
		grid.append(Array())
		next_grid.append(Array())
		salt_grid.append(Array())
		next_salt_grid.append(Array())

		# Resize auf die korrekte Größe und füllen mit 0.0
		grid[_y].resize(GRID_WIDTH)  # Resize auf GRID_WIDTH
		grid[_y].fill(0.0)  # Füllen mit 0.0

		next_grid[_y].resize(GRID_WIDTH)
		next_grid[_y].fill(0.0)

		salt_grid[_y].resize(GRID_WIDTH)
		salt_grid[_y].fill(0.0)

		next_salt_grid[_y].resize(GRID_WIDTH)
		next_salt_grid[_y].fill(0.0)

func randomize_grids():
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			grid[y][x] = randf() if randf() < 0.1 else 0.0
			salt_grid[y][x] = grid[y][x] * randf()

func update_diffusion():
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var current_water = grid[y][x]
			for offset in [
				Vector2i(-1, 0), Vector2i(1, 0), 
				Vector2i(0, -1), Vector2i(0, 1)
			]:
				var nx = (x + offset.x + GRID_WIDTH) % GRID_WIDTH
				var ny = (y + offset.y + GRID_HEIGHT) % GRID_HEIGHT

				var neighbor_water = grid[ny][nx]
				var water_diff = (current_water - neighbor_water) * DIFFUSION_RATE
				water_diff = clamp(water_diff, 0.0, current_water)

				next_grid[y][x] -= water_diff
				next_grid[ny][nx] += water_diff

			var current_salt = salt_grid[y][x]
			for offset in [
				Vector2i(-1, 0), Vector2i(1, 0), 
				Vector2i(0, -1), Vector2i(0, 1)
			]:
				var nx = (x + offset.x + GRID_WIDTH) % GRID_WIDTH
				var ny = (y + offset.y + GRID_HEIGHT) % GRID_HEIGHT

				var neighbor_salt = salt_grid[ny][nx]
				var neighbor_water = grid[ny][nx]

				if neighbor_water > 0:
					var salt_diff = (current_salt - neighbor_salt) * DIFFUSION_RATE
					salt_diff = clamp(salt_diff, 0.0, current_salt)

					next_salt_grid[y][x] -= salt_diff
					next_salt_grid[ny][nx] += salt_diff

			next_salt_grid[y][x] = min(next_salt_grid[y][x], next_grid[y][x])

	# Temporäre Variablen zum Tausch
	var temp_grid = grid
	var temp_salt_grid = salt_grid

	# Tausche die Arrays
	grid = next_grid
	salt_grid = next_salt_grid

	# Setze die "next_" Arrays auf die alten "grid" Variablen
	next_grid = temp_grid
	next_salt_grid = temp_salt_grid


func get_water_grid() -> Array:
	return grid

func get_salt_grid() -> Array:
	return salt_grid
	
func set_water(tile_coords: Vector2i,water_level: float):
	grid[tile_coords.y][tile_coords.x] = water_level;
