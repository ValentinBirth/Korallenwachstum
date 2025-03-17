extends Camera2D

# Speed of the camera movement
@export var CAMERA_SPEED: int
@onready var camera = $"."
const CAMERA_ZOOM_SPEED : Vector2 = Vector2(0.6, 0.6)
const CAMERA_ZOOM_DEFAULT : Vector2 = Vector2(1.0, 1.0)
const CAMERA_ZOOM_MIN : Vector2 = Vector2(1, 1)
const CAMERA_ZOOM_MAX : Vector2 = Vector2(1, 1)
const CAMERA_TWEEN_DURATION : float = 0.5
var m_CameraTween : Tween = null

# Store the initial limits to use in calculations
var initial_left_limit: int
var initial_right_limit: int
var initial_top_limit: int
var initial_bottom_limit: int

func _ready():
	# Store the initial camera limits set in the editor
	initial_left_limit = limit_left
	initial_right_limit = limit_right
	initial_top_limit = limit_top
	initial_bottom_limit = limit_bottom
	
	# Enable limits
	limit_smoothed = true

func _process(delta):
	var movement = Vector2.ZERO
	
	# Check for arrow key inputs
	if Input.is_action_pressed("ui_up"):
		movement.y -= 1
	if Input.is_action_pressed("ui_down"):
		movement.y += 1
	if Input.is_action_pressed("ui_left"):
		movement.x -= 1
	if Input.is_action_pressed("ui_right"):
		movement.x += 1
	
	# Normalize to maintain consistent speed when moving diagonally
	if movement != Vector2.ZERO:
		movement = movement.normalized()

	# Move the camera
	camera.position += movement * CAMERA_SPEED * delta
	
	# Handle zooming
	if Input.is_action_just_pressed("zoom_in"):
		# Calculate what the new zoom would be
		var potential_zoom = get_zoom() * (CAMERA_ZOOM_DEFAULT + CAMERA_ZOOM_SPEED)
		
		# Check if the new zoom would exceed the maximum
		if potential_zoom.x <= CAMERA_ZOOM_MAX.x and potential_zoom.y <= CAMERA_ZOOM_MAX.y:
			if m_CameraTween == null or not m_CameraTween.is_running():
				# Cancel any existing tween
				if m_CameraTween != null and m_CameraTween.is_running():
					m_CameraTween.kill()
				
				# Create new tween
				m_CameraTween = create_tween()
				
				# Calculate the target zoom (respecting max bounds)
				var target_zoom = Vector2(
					min(potential_zoom.x, CAMERA_ZOOM_MAX.x),
					min(potential_zoom.y, CAMERA_ZOOM_MAX.y)
				)
				
				# Apply the zoom
				m_CameraTween.tween_property(self, "zoom", target_zoom, CAMERA_TWEEN_DURATION).set_trans(Tween.TRANS_CUBIC)
				
				# After zoom completes, update the camera limits
				m_CameraTween.tween_callback(update_camera_limits)
	
	elif Input.is_action_just_pressed("zoom_out"):
		# Calculate what the new zoom would be
		var potential_zoom = get_zoom() / (CAMERA_ZOOM_DEFAULT + CAMERA_ZOOM_SPEED)
		
		# Check if the new zoom would exceed the minimum
		if potential_zoom.x >= CAMERA_ZOOM_MIN.x and potential_zoom.y >= CAMERA_ZOOM_MIN.y:
			if m_CameraTween == null or not m_CameraTween.is_running():
				# Cancel any existing tween
				if m_CameraTween != null and m_CameraTween.is_running():
					m_CameraTween.kill()
				
				# Create new tween
				m_CameraTween = create_tween()
				
				# Calculate the target zoom (respecting min bounds)
				var target_zoom = Vector2(
					max(potential_zoom.x, CAMERA_ZOOM_MIN.x),
					max(potential_zoom.y, CAMERA_ZOOM_MIN.y)
				)
				
				# Apply the zoom
				m_CameraTween.tween_property(self, "zoom", target_zoom, CAMERA_TWEEN_DURATION).set_trans(Tween.TRANS_CUBIC)
				
				# After zoom completes, update the camera limits
				m_CameraTween.tween_callback(update_camera_limits)

# Update camera limits based on the current zoom level
func update_camera_limits():
	# Calculate margin based on viewport size and zoom
	var half_viewport = get_viewport_rect().size / 2
	var zoom_factor = Vector2(1.0 / zoom.x, 1.0 / zoom.y)
	var margin = half_viewport * zoom_factor
	
	# Adjust limits based on zoom level
	limit_left = initial_left_limit + int(margin.x)
	limit_right = initial_right_limit - int(margin.x)
	limit_top = initial_top_limit + int(margin.y)
	limit_bottom = initial_bottom_limit - int(margin.y)
	
	# Ensure the camera respects the new limits
	force_update_scroll()
