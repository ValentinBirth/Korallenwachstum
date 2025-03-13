extends Node2D

var speed = 1.0
var stuck = false

func _process(delta):
	if stuck:
		return
	
	# Random movement (4 directions)
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	position += directions[randi() % 4] * speed

func stick():
	stuck = true
	# Change color or add effect when it attaches
	$ColorRect.color = Color(1, 0.5, 0.2)
