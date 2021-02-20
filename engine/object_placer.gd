extends TileMap

func _ready():

	for tile in get_used_cells():
		var tile_name = get_tileset().tile_get_name(get_cellv(tile))
		
		# tile name is folder/scenename
		var tile_path = "res://" + tile_name + ".tscn"
		
		var node = load(tile_path).instance()

		# rotate the node to match the cell - this is made harder by a lack of rotation 
		# degrees for the cell, instead we rely on transforms, yay! group theory!
		if is_cell_transposed(tile.x, tile.y) && is_cell_x_flipped(tile.x, tile.y):
			node.set_global_rotation_degrees(90)
		elif is_cell_y_flipped(tile.x, tile.y) && is_cell_x_flipped(tile.x, tile.y):
			node.set_global_rotation_degrees(180)
		elif is_cell_transposed(tile.x, tile.y) && is_cell_y_flipped(tile.x, tile.y):
			node.set_global_rotation_degrees(270)


		# if the node has Sprite in the first layer, we'll use its size, otherwise we'll assume it is cell_sized
		var scene_size = cell_size
		if node.get_node("Sprite"):
			scene_size =  node.get_node("Sprite").texture.get_size()
			# if we rotated the scene then we need to transpose it.
			if node.get_global_rotation_degrees() in [90, 270]:
				scene_size =  Vector2(scene_size.y, scene_size.x)	
		node.global_position = map_to_world(tile) + scene_size/2 + get_tileset().tile_get_texture_offset(get_cellv(tile))
		get_parent().call_deferred("add_child", node)
	clear()
