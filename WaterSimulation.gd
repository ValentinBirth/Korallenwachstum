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
			
func update_simulation():
	var updates = []
	 # Collect cells with water for processing
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if grid[y][x] > 0:
				updates.append(Vector2i(x, y))
				
	# Copy current grid state			
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			next_grid[y][x] = grid[y][x]
			next_salt_grid[y][x] = salt_grid[y][x]
			
	# Process water movement
	for cell in updates:
		move_water(cell.x, cell.y)

	# Process salt diffusion only where water exists
	for cell in updates:
		if salt_grid[cell.y][cell.x] > 0:
			diffuse_salt(cell.x, cell.y)
				
				
	# Swap grids
	var temp = grid
	grid = next_grid
	next_grid = temp

	next_salt_grid = temp
	
func move_water(x: int, y: int):
	var water_amount = grid[y][x]
	if water_amount <= 0:
		return

	# Move down if possible
	if y + 1 < GRID_HEIGHT and grid[y + 1][x] < 1.0:
		var flow = min(water_amount, 1.0 - grid[y + 1][x])
		var salt_flow = salt_grid[y][x] * (flow / water_amount)
		next_grid[y][x] -= flow
		next_grid[y + 1][x] += flow
		next_salt_grid[y][x] -= salt_flow
		next_salt_grid[y + 1][x] += salt_flow
	# Move sideways if blocked
	elif y + 1 < GRID_HEIGHT:
		var move_left = x > 0 and grid[y][x - 1] < 1.0
		var move_right = x < GRID_WIDTH - 1 and grid[y][x + 1] < 1.0
		if move_left and move_right:
			var flow = water_amount / 2.0
			var salt_flow = salt_grid[y][x] * (flow / water_amount)
			next_grid[y][x] -= flow
			next_grid[y][x - 1] += flow / 2
			next_grid[y][x + 1] += flow / 2
			next_salt_grid[y][x] -= salt_flow
			next_salt_grid[y][x - 1] += salt_flow / 2
			next_salt_grid[y][x + 1] += salt_flow / 2
		elif move_left:
			var flow = min(water_amount, 1.0 - grid[y][x - 1])
			var salt_flow = salt_grid[y][x] * (flow / water_amount)
			next_grid[y][x] -= flow
			next_grid[y][x - 1] += flow
			next_salt_grid[y][x] -= salt_flow
			next_salt_grid[y][x - 1] += salt_flow
		elif move_right:
			var flow = min(water_amount, 1.0 - grid[y][x + 1])
			var salt_flow = salt_grid[y][x] * (flow / water_amount)
			next_grid[y][x] -= flow
			next_grid[y][x + 1] += flow
			next_salt_grid[y][x] -= salt_flow
			next_salt_grid[y][x + 1] += salt_flow
			
func diffuse_salt(x: int, y: int):
	var salt_amount = salt_grid[y][x]
	if salt_amount <= 0:
		return
		
	var neighbors = []
	var neighbor_offsets = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]
	for offset in neighbor_offsets:
		var nx = x + offset.x
		var ny = y + offset.y
		if nx >= 0 and nx < GRID_WIDTH and ny >= 0 and ny < GRID_HEIGHT and grid[ny][nx] > 0:
			neighbors.append(Vector2(nx, ny))
		
	if neighbors.size() == 0:
		return

	var diffusion_amount = salt_amount * DIFFUSION_RATE / neighbors.size()
	
	next_salt_grid[y][x] -= diffusion_amount * neighbors.size()
	for neighbor in neighbors:
		next_salt_grid[neighbor.y][neighbor.x] += diffusion_amount

func get_water_grid() -> Array:
	return grid

func get_salt_grid() -> Array:
	return salt_grid
	
func set_water(tile_coords: Vector2i,water_level: float):
	grid[tile_coords.y][tile_coords.x] = water_level;

func set_salt(tile_coords: Vector2i,salt_level: float):
	salt_grid[tile_coords.y][tile_coords.x] = salt_level;
