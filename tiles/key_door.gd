extends StaticBody2D

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("nopush")
	add_to_group("door")
	add_to_group("persist")
	
func interact(node):
	# I node.keys instead of node.get(keys) with because I want this 
	# to fail if the player does not have a keys variable
	if node.keys > 0:
		# Use a key and then delete the door.
		node.keys -= 1
		queue_free()

func save():
	var save_dict = {
		"filename"	: get_filename(),
		"parent"		: get_parent().get_path(),
		"pos_x"		: position.x, # Vector2 is not supported by JSON
		"pos_y"		: position.y,
		"rotation"	: rotation
	}
	return save_dict
