extends Object

class_name WaterSimulation

# Configuration parameters that can be adjusted
@export var MAX_WATER: float = 1.0
@export var DIFFUSION_RATE: float = 0.25
@export var SURFACE_TENSION: float = 0.05
@export var SALT_DIFFUSION_RATE: float = 0.1

# Class for managing water and salt in a single cell
class WaterCell:
	var water_amount: float = 0.0
	var salt_amount: float = 0.0
	
	func _init(w: float = 0.0, s: float = 0.0):
		water_amount = w
		salt_amount = s
	
	func get_salt_concentration() -> float:
		# Calculate salt concentration, avoiding division by zero
		return salt_amount / water_amount if water_amount > 0.001 else 0.0
	
	func has_water() -> bool:
		# Check if the cell has a meaningful amount of water
		return water_amount > 0.001
	
	func calculate_viscosity() -> float:
		# Higher salt concentration = higher viscosity
		return 1.0 + get_salt_concentration() * 0.5  # 50% more viscous when fully saturated

# Reference to the terrain layer
var terrain_layer: TileMapLayer = null

# Dictionary to store water cells
var cells = {}  # Dictionary of Vector2i -> WaterCell

# Active cells tracking using a dictionary as a set for O(1) lookups
var active_cells = {}
var debug_mode: bool = false

# Function to set the terrain layer (so we can use it for collision checks)
func set_terrain_layer(layer: TileMapLayer):
	terrain_layer = layer

# Function to check if a cell is solid (based on terrain layer)
func is_solid(pos: Vector2i) -> bool:
	if terrain_layer == null:
		return false
	return terrain_layer.get_cell_source_id(pos) != -1  # Check if a tile exists

# Getter for water grid (compatibility with existing code)
func get_water_grid() -> Dictionary:
	var water_grid = {}
	for pos in cells:
		water_grid[pos] = cells[pos].water_amount
	return water_grid

# Getter for salt grid (compatibility with existing code)
func get_salt_grid() -> Dictionary:
	var salt_grid = {}
	for pos in cells:
		salt_grid[pos] = cells[pos].salt_amount
	return salt_grid

# Setter for water at a specific position
func set_water(pos: Vector2i, amount: float):
	if amount <= 0:
		return
		
	# Initialize cell if it doesn't exist
	if !cells.has(pos):
		cells[pos] = WaterCell.new()
	
	cells[pos].water_amount = amount
	
	# Add to active cells
	active_cells[pos] = true

# Setter for salt at a specific position
func set_salt(pos: Vector2i, amount: float):
	if amount <= 0:
		return
		
	# Initialize cell if it doesn't exist
	if !cells.has(pos):
		cells[pos] = WaterCell.new()
	
	cells[pos].salt_amount = amount

# Apply the flow of water and salt between two cells
func apply_flow(from_pos: Vector2i, to_pos: Vector2i, water_amount: float, salt_amount: float) -> void:
	# Initialize cells if they don't exist
	for pos in [from_pos, to_pos]:
		if !cells.has(pos):
			cells[pos] = WaterCell.new()
	
	# Calculate available space in target cell
	var to_cell = cells[to_pos]
	var total_space = MAX_WATER - to_cell.water_amount
	
	# Calculate the flow based on the available space
	var flow = min(water_amount, total_space)
	if flow <= 0.001:  # Don't flow if there's no meaningful space or water
		return
	
	var from_cell = cells[from_pos]
	
	# Calculate salt flow in proportion to the water flow
	var salt_flow = 0.0
	if from_cell.water_amount > 0.001:  # Avoid division by very small numbers
		salt_flow = salt_amount * (flow / from_cell.water_amount)
	
	# Apply flow to the cells
	from_cell.water_amount -= flow
	to_cell.water_amount += flow
	from_cell.salt_amount -= salt_flow
	to_cell.salt_amount += salt_flow
	
	# Track active cells
	if from_cell.has_water():
		active_cells[from_pos] = true
	else:
		active_cells.erase(from_pos)
		
	if to_cell.has_water():
		active_cells[to_pos] = true
	else:
		active_cells.erase(to_pos)

# Main function for moving water
func move_water(pos: Vector2i):
	if !cells.has(pos) or !cells[pos].has_water():
		return
		
	var cell = cells[pos]
	var water_amount = cell.water_amount
	var salt_amount = cell.salt_amount
	var viscosity = cell.calculate_viscosity()
	
	# Calculate positions of neighboring cells
	var pos_below = pos + Vector2i(0, 1)
	var pos_left = pos + Vector2i(-1, 0)
	var pos_right = pos + Vector2i(1, 0)
	
	# Try to move down if possible
	if !is_solid(pos_below):
		var below_water = 0.0
		if cells.has(pos_below):
			below_water = cells[pos_below].water_amount
			
		if below_water < MAX_WATER:
			# Calculate flow amount with viscosity and surface tension
			var available_space = MAX_WATER - below_water
			var flow_amount = min(water_amount, available_space) * (1.0 - SURFACE_TENSION) / viscosity
			
			if flow_amount > 0.001:
				apply_flow(pos, pos_below, flow_amount, salt_amount * (flow_amount / water_amount))
				return  # Exit early after downward movement
	
	# If downward movement is blocked, try moving sideways
	var move_left = pos.x > 0 and !is_solid(pos_left)
	var move_right = !is_solid(pos_right)
	
	# Get water levels in neighboring cells
	var left_water = 0.0
	var right_water = 0.0
	
	if cells.has(pos_left):
		left_water = cells[pos_left].water_amount
		
	if cells.has(pos_right):
		right_water = cells[pos_right].water_amount
		
	move_left = move_left and left_water < MAX_WATER
	move_right = move_right and right_water < MAX_WATER
	
	if move_left and move_right:
		# Distribute water evenly between the three cells
		var positions = [pos, pos_left, pos_right]
		distribute_water_evenly(positions, viscosity)
	elif move_left:
		# Distribute water evenly between current and left cells
		var positions = [pos, pos_left]
		distribute_water_evenly(positions, viscosity)
	elif move_right:
		# Distribute water evenly between current and right cells
		var positions = [pos, pos_right]
		distribute_water_evenly(positions, viscosity)

# Distribute water evenly between cells with surface tension and viscosity effects
func distribute_water_evenly(positions: Array, viscosity: float) -> void:
	# Calculate current total water across all positions
	var total_water = 0.0
	var current_levels = {}
	
	for pos in positions:
		var amount = 0.0
		if cells.has(pos):
			amount = cells[pos].water_amount
		total_water += amount
		current_levels[pos] = amount
	
	# Calculate target water level (even distribution)
	var target_level = total_water / positions.size()
	
	# Apply flows to reach target level, accounting for surface tension and viscosity
	for pos in positions:
		var current_level = current_levels[pos]
		var difference = target_level - current_level
		
		# Only flow if the difference is significant
		if abs(difference) > 0.001:
			if difference > 0:  # This cell needs to receive water
				# Find cells that have excess water
				for donor_pos in positions:
					if donor_pos == pos:
						continue
						
					var donor_level = current_levels[donor_pos]
					if donor_level > target_level:
						var flow_amount = min(donor_level - target_level, target_level - current_level)
						
						# Adjust for surface tension and viscosity
						flow_amount *= (1.0 - SURFACE_TENSION) / viscosity
						
						if flow_amount > 0.001 and cells.has(donor_pos) and cells[donor_pos].has_water():
							var donor_cell = cells[donor_pos]
							var salt_flow = 0.0
							
							if donor_cell.water_amount > 0.001:
								salt_flow = donor_cell.salt_amount * (flow_amount / donor_cell.water_amount)
								
							apply_flow(donor_pos, pos, flow_amount, salt_flow)
							
							# Update current levels for next iteration
							current_levels[donor_pos] -= flow_amount
							current_levels[pos] += flow_amount

# Apply salt diffusion between cells
func diffuse_salt():
	var salt_diffusion = {}
	
	# Check each water cell with salt
	for pos in active_cells.keys():
		if !cells.has(pos) or !cells[pos].has_water():
			continue
			
		var cell = cells[pos]
		if cell.salt_amount <= 0.001:
			continue
			
		var salt_conc_current = cell.get_salt_concentration()
		
		# Check neighboring cells
		for offset in [Vector2i(0,1), Vector2i(1,0), Vector2i(0,-1), Vector2i(-1,0)]:
			var neighbor_pos = pos + offset
			
			# Skip if neighbor is solid
			if is_solid(neighbor_pos):
				continue
				
			# Only diffuse to cells with water
			if cells.has(neighbor_pos) and cells[neighbor_pos].has_water():
				var neighbor_cell = cells[neighbor_pos]
				var salt_conc_neighbor = neighbor_cell.get_salt_concentration()
				
				if salt_conc_current > salt_conc_neighbor:
					# Calculate diffusion amount based on concentration difference
					var diffusion_amount = (salt_conc_current - salt_conc_neighbor) * SALT_DIFFUSION_RATE * cell.water_amount
					
					# Ensure we don't diffuse more salt than we have
					diffusion_amount = min(diffusion_amount, cell.salt_amount * 0.5)
					
					# Store diffusion for later application
					if !salt_diffusion.has(pos):
						salt_diffusion[pos] = 0.0
					if !salt_diffusion.has(neighbor_pos):
						salt_diffusion[neighbor_pos] = 0.0
						
					salt_diffusion[pos] -= diffusion_amount
					salt_diffusion[neighbor_pos] += diffusion_amount
	
	# Apply all diffusion changes at once
	for pos in salt_diffusion.keys():
		if !cells.has(pos):
			cells[pos] = WaterCell.new()
		cells[pos].salt_amount += salt_diffusion[pos]

# Update simulation
func update_simulation():
	if debug_mode:
		print("=== Water Grid Before Update ===")
		for pos in cells.keys():
			if cells[pos].has_water():
				print("Cell: ", pos, " | Water: ", cells[pos].water_amount, " | Salt: ", cells[pos].salt_amount)
	
	# Create a copy of active cells keys to iterate through
	var current_active_cells = active_cells.keys()
	
	# Process water movement
	for pos in current_active_cells:
		if cells.has(pos) and cells[pos].has_water():
			move_water(pos)
	
	# Apply salt diffusion
	diffuse_salt()
	
	# Clean up cells with negligible water
	var cells_to_remove = []
	for pos in cells.keys():
		if !cells[pos].has_water():
			cells_to_remove.append(pos)
			active_cells.erase(pos)
	
	for pos in cells_to_remove:
		cells.erase(pos)
		
	if debug_mode:
		print("=== Water Grid After Update ===")
		for pos in cells.keys():
			if cells[pos].has_water():
				print("Cell: ", pos, " | Water: ", cells[pos].water_amount, " | Salt: ", cells[pos].salt_amount)
