extends TileMapLayer

@export var tile_color: Color = Color(0, 1, 0, 1)  # Standardfarbe Grün
@export var tile_layer: int = 0  # Standardmäßig Ebene 0 (kann angepasst werden)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var tilemap = get_parent() as TileMap  # `TileMapLayer` hat keine `local_to_map()`, daher `TileMap` abrufen
		if tilemap:
			var tile_pos = tilemap.local_to_map(mouse_pos)  # Wandelt Mausposition in Tile-Position um
			color_tile(tile_pos, tile_color)

func color_tile(pos: Vector2i, color: Color):
	var tilemap = get_parent() as TileMap
	if tilemap:
		var tile_data = tilemap.get_cell_tile_data(tile_layer, pos)
		if tile_data:
			tile_data.set_custom_data("modulate", color)  # Ändert die Farbe der Kachel
