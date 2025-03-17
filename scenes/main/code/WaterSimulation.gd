extends Object

class_name WaterSimulation

# Configuration parameters that can be adjusted
@export var MAX_WATER: float = 1.0
@export var SALT_DIFFUSION_RATE: float = 0.25
@export var VELOCITY_TRANSFER: float = 0.8
@export var MAX_VELOCITY: float = 6.0
@export var GRAVITY_FORCE: float = 9.8
@export var step_time = 0.05

var terrain_layer: TileMapLayer = null
var water_layer: TileMapLayer = null

# Dictionary to store water cells
var cells = {}  # Dictionary of Vector2i -> WaterCell

# Active cells tracking using a dictionary as a set for O(1) lookups
var active_cells = {}
var debug_mode: bool = false

# Arrays to store sources and drains
var sources: Array[WaterSource] = []
var drains: Array[WaterDrain] = []

# Class for managing water and salt in a single cell
class WaterCell:
	var water_amount: float = 0.0
	var salt_amount: float = 0.0
	var velocity: Vector2 = Vector2.ZERO  # Add velocity vector
	
	func _init(w: float = 0.0, s: float = 0.0):
		water_amount = w
		salt_amount = s
		velocity = Vector2.ZERO
	
	func get_salt_concentration() -> float:
		# Calculate salt concentration, avoiding division by zero
		return salt_amount / water_amount if water_amount > 0.001 else 0.0

	func has_water() -> bool:
		# Check if the cell has a meaningful amount of water
		return water_amount > 0.001

# Source class to generate water at a specific location
class WaterSource:
	var position: Vector2i
	var water_rate: float      # Amount of water to generate per update
	var salt_concentration: float  # Salt concentration in the generated water
	
	func _init(pos: Vector2i, water_amount: float = 0.1, salt_conc: float = 0.0):
		position = pos
		water_rate = water_amount
		salt_concentration = salt_conc

# Drain class to remove water at a specific location
class WaterDrain:
	var position: Vector2i
	var drain_rate: float      # Amount of water to drain per update
	
	func _init(pos: Vector2i, rate: float = 0.1):
		position = pos
		drain_rate = rate

func set_water_layer(layer: TileMapLayer):
	water_layer = layer
	
func set_terrain_layer(layer: TileMapLayer):
	terrain_layer = layer

func update_velocities():
	var active_positions = active_cells.keys()
	for pos in active_positions:
		if !cells.has(pos) or !cells[pos].has_water():
			continue
			
		var cell = cells[pos]
		
		# Apply gravity to velocity
		cell.velocity.y += GRAVITY_FORCE * step_time
		
		# Apply floor and wall friction/collision
		var pos_below = pos + Vector2i(0, 1)
		var pos_left = pos + Vector2i(-1, 0)
		var pos_right = pos + Vector2i(1, 0)
		
		# Check below for floor
		if is_solid(pos_below) or (cells.has(pos_below) and cells[pos_below].water_amount >= MAX_WATER):
			# Redirect velocity horizontally when hitting floor
			if cell.velocity.y > 0:
				# Distribute vertical momentum to horizontal
				var horizontal_force = cell.velocity.y * 0.5
				cell.velocity.x += horizontal_force * (randf() * 2.0 - 1.0)  # Random left or right
				cell.velocity.y *= -0.1  # Slight bounce
		
		# Check sides for walls
		if is_solid(pos_left) and cell.velocity.x < 0:
			cell.velocity.x *= -0.5  # Bounce with energy loss
		
		if is_solid(pos_right) and cell.velocity.x > 0:
			cell.velocity.x *= -0.5  # Bounce with energy loss
		
		# Clamp velocity to maximum
		if cell.velocity.length() > MAX_VELOCITY:
			cell.velocity = cell.velocity.normalized() * MAX_VELOCITY
			
		if cell.velocity.length() < 0.05:
			cell.velocity = Vector2.ZERO  # Stop unnecessary tiny movements

# Function to set up hardcoded sources
func setup_sources(source_positions: Array, source_water_rate: float, source_salt_concentration: float):
	sources.clear()
	for pos in source_positions:
		sources.append(WaterSource.new(pos, source_water_rate, source_salt_concentration))

# Function to set up hardcoded drains
func setup_drains(drain_positions: Array, drain_rate: float):
	drains.clear()
	for pos in drain_positions:
		drains.append(WaterDrain.new(pos, drain_rate))

# Function to fill the terraint with water once
func fill_pool():
	var min_x = -64
	var max_x = 14
	for x in range(min_x,max_x):
		var y_level = 24
		while y_level >=0:
			var pos = Vector2i(x,y_level)
			if !is_solid(pos):
				set_water(pos,1,0)
			y_level -= 1
	return

# Function to check if a cell is solid (based on terrain layer)
func is_solid(pos: Vector2i) -> bool:
	if terrain_layer == null:
		return false
	var world_pos = water_layer.to_global(pos)
	var terrain_pos = terrain_layer.to_local(world_pos)
	return terrain_layer.get_cell_source_id(terrain_pos) != -1  # Check if a tile exists

# Getter for water grid
func get_water_grid() -> Dictionary:
	return cells

# Setter for water at a specific position
func set_water(pos: Vector2i, water_ammount: float, salt_ammount: float):
	if water_ammount <= 0:
		return
		
	# Initialize cell if it doesn't exist
	if !cells.has(pos):
		cells[pos] = WaterCell.new()
	
	cells[pos].water_amount = water_ammount
	cells[pos].salt_amount = salt_ammount
	
	# Add to active cells
	active_cells[pos] = true
# Get all sources
func get_source_positions() -> Array:
	return sources

# Get all drains
func get_drain_positions() -> Array:
	return drains

# Apply sources to generate water
func apply_sources():
	for source in sources:
		# Skip if source position is solid
		if is_solid(source.position):
			continue
		
		# Initialize cell if it doesn't exist
		if !cells.has(source.position):
			cells[source.position] = WaterCell.new()
		
		var cell = cells[source.position]
		
		# Calculate how much water we can add (respect MAX_WATER limit)
		var available_space = MAX_WATER - cell.water_amount
		var water_to_add = min(source.water_rate, available_space)
		
		if water_to_add > 0.001:
			cell.water_amount += water_to_add
			
			# Calculate salt to add based on concentration
			var salt_to_add = water_to_add * source.salt_concentration
			cell.salt_amount += salt_to_add
			
			# Mark cell as active
			active_cells[source.position] = true

# Apply drains to remove water
func apply_drains():
	for drain in drains:
		# Skip if no water at this position
		if !cells.has(drain.position) or !cells[drain.position].has_water():
			continue
		
		var cell = cells[drain.position]
		
		# Calculate how much water we can remove
		var water_to_remove = min(drain.drain_rate, cell.water_amount)
		
		if water_to_remove > 0.001:
			# Calculate how much salt to remove (proportional to water)
			var salt_proportion = water_to_remove / cell.water_amount
			var salt_to_remove = cell.salt_amount * salt_proportion
			
			# Apply the drain
			cell.water_amount -= water_to_remove
			cell.salt_amount -= salt_to_remove
			
			# Check if cell should be deactivated
			if !cell.has_water():
				active_cells.erase(drain.position)

# Modified apply_flow function that also transfers velocity
func apply_flow_with_velocity(from_pos: Vector2i, to_pos: Vector2i, water_amount: float, salt_amount: float, velocity: Vector2) -> void:
	# Initialize cells if they don't exist
	if !cells.has(from_pos):
		cells[from_pos] = WaterCell.new()
	if !cells.has(to_pos):
		cells[to_pos] = WaterCell.new()
	
	var from_cell = cells[from_pos]
	var to_cell = cells[to_pos]
	
	# Calculate the flow
	var flow = min(water_amount, MAX_WATER - to_cell.water_amount)
	if flow <= 0.001:
		return
	
	# Calculate salt flow
	var salt_flow = 0.0
	if from_cell.water_amount > 0.001:
		salt_flow = salt_amount * (flow / from_cell.water_amount)
	
	# Calculate velocity transfer
	var velocity_transfer = from_cell.velocity.lerp(velocity, 0.5) * VELOCITY_TRANSFER
	
	# Calculate new velocities based on conservation of momentum
	var total_water_after = to_cell.water_amount + flow
	
	# Mix velocities based on mass (water amount)
	var new_velocity = Vector2.ZERO
	if total_water_after > 0.001:
		new_velocity = (to_cell.velocity * to_cell.water_amount + velocity_transfer * flow) / total_water_after
	
	# Apply flow to the cells
	from_cell.water_amount -= flow
	to_cell.water_amount += flow
	from_cell.salt_amount -= salt_flow
	to_cell.salt_amount += salt_flow
	
	# Apply new velocity
	to_cell.velocity = new_velocity
	
	# Track active cells
	if from_cell.has_water():
		active_cells[from_pos] = true
	else:
		active_cells.erase(from_pos)
		
	if to_cell.has_water():
		active_cells[to_pos] = true
	else:
		active_cells.erase(to_pos)
		
# Helper function to get primary direction from velocity vector
func get_primary_direction(velocity_dir: Vector2) -> Vector2i:
	# Determine which direction (up, down, left, right) best matches the velocity
	if abs(velocity_dir.x) > abs(velocity_dir.y):
		return Vector2i(sign(velocity_dir.x), 0)  # Left or right
	else:
		return Vector2i(0, sign(velocity_dir.y))  # Up or down

# Helper function to get secondary direction from velocity vector
func get_secondary_direction(velocity_dir: Vector2) -> Vector2i:
	# Get the orthogonal direction to primary
	if abs(velocity_dir.x) > abs(velocity_dir.y):
		return Vector2i(0, sign(velocity_dir.y))  # Up or down
	else:
		return Vector2i(sign(velocity_dir.x), 0)  # Left or right
		
# Try to flow water in a specific direction based on velocity
func try_flow_with_velocity(from_pos: Vector2i, to_pos: Vector2i, velocity: Vector2) -> bool:
	if is_solid(to_pos):
		return false
		
	if !cells.has(from_pos) or !cells[from_pos].has_water():
		return false
		
	var from_cell = cells[from_pos]
	var to_water = 0.0
	
	if cells.has(to_pos):
		to_water = cells[to_pos].water_amount
		
	if to_water >= MAX_WATER:
		return false
		
	var available_space = MAX_WATER - to_water
	var velocity_magnitude = velocity.length()
	
	# Calculate flow amount based on velocity and available space
	var flow_proportion = min(0.15 + velocity_magnitude * 0.05, 1)  # Higher velocity causes more flow
	var flow_amount = min(from_cell.water_amount * flow_proportion, available_space)
	
	if flow_amount <= 0.001:
		return false
		
	var salt_amount = 0.0
	if from_cell.water_amount > 0.001:
		salt_amount = from_cell.salt_amount * (flow_amount / from_cell.water_amount)
		
	apply_flow_with_velocity(from_pos, to_pos, flow_amount, salt_amount, velocity)
	return true
	
# Main function for moving water
func move_water(pos: Vector2i):
	if !cells.has(pos) or !cells[pos].has_water():
		return
		
	var cell = cells[pos]
	
	# Calculate positions based on velocity direction
	var velocity_direction = cell.velocity.normalized()
	var primary_direction = get_primary_direction(velocity_direction)
	var secondary_direction = get_secondary_direction(velocity_direction)
	
	# Try to move in primary direction first
	var primary_pos = pos + primary_direction
	if !is_solid(primary_pos) and try_flow_with_velocity(pos, primary_pos, cell.velocity):
		return
	
	# Try to move in secondary direction if primary failed
	var secondary_pos = pos + secondary_direction
	if !is_solid(secondary_pos) and try_flow_with_velocity(pos, secondary_pos, cell.velocity * 0.7):
		return


func distribute_water_evenly_with_velocity(positions: Array) -> void:
	# Calculate current total water across all positions
	var total_water = 0.0
	var current_levels = {}
	var cell_velocities = {}
	
	for pos in positions:
		var amount = 0.0
		var vel = Vector2.ZERO
		
		if cells.has(pos) and cells[pos].has_water():
			amount = cells[pos].water_amount
			vel = cells[pos].velocity
			
		total_water += amount
		current_levels[pos] = amount
		cell_velocities[pos] = vel
	
	# Calculate target water level (even distribution)
	var target_level = total_water / positions.size()
	
	# Apply flows to reach target level, accounting velocity
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
						
						if flow_amount > 0.001 and cells.has(donor_pos) and cells[donor_pos].has_water():
							var donor_cell = cells[donor_pos]
							var salt_flow = 0.0
							
							if donor_cell.water_amount > 0.001:
								salt_flow = donor_cell.salt_amount * (flow_amount / donor_cell.water_amount)
							
							# Calculate flow direction for velocity
							var flow_direction = Vector2(pos.x - donor_pos.x, pos.y - donor_pos.y).normalized()
							var velocity_contrib = flow_direction * 0.5 + donor_cell.velocity * 0.5
							
							apply_flow_with_velocity(donor_pos, pos, flow_amount, salt_flow, velocity_contrib)
							
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

# Modify the update_simulation function to include velocity updates
func update_simulation():
	# Apply sources to generate water
	apply_sources()
	
	# Update velocities for all active cells
	update_velocities()
	
	# Create a copy of active cells keys to iterate through
	var current_active_cells = active_cells.keys()
	
	# Process water movement
	for pos in current_active_cells:
		if cells.has(pos) and cells[pos].has_water():
			move_water(pos)
	
	# Apply salt diffusion
	diffuse_salt()
	
	# Apply drains to remove water
	apply_drains()
	
	# Clean up cells with negligible water
	var cells_to_remove = []
	for pos in cells.keys():
		if !cells[pos].has_water():
			cells_to_remove.append(pos)
			active_cells.erase(pos)
	
	for pos in cells_to_remove:
		cells.erase(pos)
