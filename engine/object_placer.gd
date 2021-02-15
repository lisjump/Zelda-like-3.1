extends TileMap

func _ready():
	for tile in get_used_cells():
		var tile_name = get_tileset().tile_get_name(get_cellv(tile))
		
		# tile name is folder_scenename, we split to separate them
		# and create the path to the scene
		var tile_split = tile_name.split('_')
		var tile_path = "res://" + tile_split[0] + "/" + tile_split[1] + ".tscn"
		
		var node = load(tile_path).instance()
		node.global_position = map_to_world(tile) + cell_size/2 + get_tileset().tile_get_texture_offset(get_cellv(tile))
		get_parent().call_deferred("add_child", node)
	clear()
