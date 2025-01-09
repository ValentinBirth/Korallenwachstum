extends Camera2D

# Speed of the camera movement
@export var CAMERA_SPEED: int
@onready var camera = $"."
# Lower cap for the `_zoom_level`.
@export var min_zoom := 0.5
# Upper cap for the `_zoom_level`.
@export var max_zoom := 2.0
const CAMERA_ZOOM_SPEED : Vector2 = Vector2(0.6, 0.6)
const CAMERA_ZOOM_DEFAULT : Vector2 = Vector2(1.0, 1.0)
const CAMERA_ZOOM_MIN : Vector2 = Vector2(0.6, 0.6)
const CAMERA_ZOOM_MAX : Vector2 = Vector2(2.0, 2.0)
const CAMERA_TWEEN_DURATION : float = 0.5
var m_CameraTween : Tween = null

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

	# Move the camera's parent (this Node2D)
	camera.position += movement * CAMERA_SPEED * delta
	
	if (Input.is_action_just_pressed("zoom_in")):
		if (get_zoom() < CAMERA_ZOOM_MAX):
			if (m_CameraTween == null or not m_CameraTween.is_running()):
				m_CameraTween = create_tween()
				m_CameraTween.tween_property(self, "zoom", get_zoom() * (CAMERA_ZOOM_DEFAULT + CAMERA_ZOOM_SPEED),
												CAMERA_TWEEN_DURATION).set_trans(Tween.TRANS_CUBIC)
		
	elif (Input.is_action_just_pressed("zoom_out")):
		if (get_zoom() > CAMERA_ZOOM_MIN):
			if (m_CameraTween == null or not m_CameraTween.is_running()):
				m_CameraTween = create_tween()
				m_CameraTween.tween_property(self, "zoom", get_zoom() / (CAMERA_ZOOM_DEFAULT + CAMERA_ZOOM_SPEED),
												CAMERA_TWEEN_DURATION).set_trans(Tween.TRANS_CUBIC)
