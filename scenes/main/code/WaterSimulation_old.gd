extends Object

class_name WaterSimulationOld

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

	temp = salt_grid
	salt_grid = next_salt_grid
	next_salt_grid = temp
	
# Helper function to handle water and salt movement
func apply_flow(from_x: int, from_y: int, to_x: int, to_y: int, water_amount: float, total_space: float, salt_amount: float) -> void:
	# Only move if there's available space and a non-zero flow
	var flow = min(water_amount, total_space)
	if flow <= 0:  # Don't flow if there's no space or no water to move
		return
		
	var salt_flow = salt_amount * (flow / water_amount) if water_amount > 0 else 0.0
	
	# Apply flow to the grids
	next_grid[from_y][from_x] -= flow
	next_grid[to_y][to_x] += flow
	next_salt_grid[from_y][from_x] -= salt_flow
	next_salt_grid[to_y][to_x] += salt_flow

# Main function for moving water
func move_water(x: int, y: int):
	var water_amount = grid[y][x]
	if water_amount <= 0:
		return

	# Try to move down if possible
	if y + 1 < GRID_HEIGHT and grid[y + 1][x] < 1.0:  # Only move down if there is space
		var flow_amount = min(water_amount, 1.0 - grid[y + 1][x])  # Flow amount depends on available space
		if flow_amount > 0:  # Only move if there is actual space to flow
			apply_flow(x, y, x, y + 1, water_amount, 1.0 - grid[y + 1][x], salt_grid[y][x])
			return  # Exit early after downward movement

	# If downwards movement is blocked, try moving sideways
	var move_left = x > 0 and grid[y][x - 1] < 1.0
	var move_right = x < GRID_WIDTH - 1 and grid[y][x + 1] < 1.0

	if move_left and move_right:
		# Calculate total water in the current, left, and right cells
		var total_water = water_amount + grid[y][x - 1] + grid[y][x + 1]
		var target_level = total_water / 3.0  # Even out the water level between the 3 cells
		
		# Calculate the water flow for each direction
		var flow_left = max(0, target_level - grid[y][x - 1])
		var flow_right = max(0, target_level - grid[y][x + 1])
		var flow_current = water_amount - flow_left - flow_right

		# Move water to left and right cells
		apply_flow(x, y, x - 1, y, flow_left, 1.0 - grid[y][x - 1], salt_grid[y][x] * (flow_left / water_amount))
		apply_flow(x, y, x + 1, y, flow_right, 1.0 - grid[y][x + 1], salt_grid[y][x] * (flow_right / water_amount))
		
		# Keep the remaining water in the current cell
		apply_flow(x, y, x, y, flow_current, 1.0 - grid[y][x], salt_grid[y][x] * (flow_current / water_amount))

	elif move_left:
		# Calculate total water in the current and left cells
		var total_water = water_amount + grid[y][x - 1]
		var target_level = total_water / 2.0  # Even out the water level between the current and left cell
		
		# Calculate the water flow for the left direction
		var flow_left = max(0, target_level - grid[y][x - 1])
		var flow_current = water_amount - flow_left

		# Move water to the left cell and keep the remaining water in the current cell
		apply_flow(x, y, x - 1, y, flow_left, 1.0 - grid[y][x - 1], salt_grid[y][x] * (flow_left / water_amount))
		apply_flow(x, y, x, y, flow_current, 1.0 - grid[y][x], salt_grid[y][x] * (flow_current / water_amount))

	elif move_right:
		# Calculate total water in the current and right cells
		var total_water = water_amount + grid[y][x + 1]
		var target_level = total_water / 2.0  # Even out the water level between the current and right cell
		
		# Calculate the water flow for the right direction
		var flow_right = max(0, target_level - grid[y][x + 1])
		var flow_current = water_amount - flow_right

		# Move water to the right cell and keep the remaining water in the current cell
		apply_flow(x, y, x + 1, y, flow_right, 1.0 - grid[y][x + 1], salt_grid[y][x] * (flow_right / water_amount))
		apply_flow(x, y, x, y, flow_current, 1.0 - grid[y][x], salt_grid[y][x] * (flow_current / water_amount))

												
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
