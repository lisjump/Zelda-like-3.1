extends pickup

func _ready():
	add_to_group("persist")
	
func body_entered(body):
	# I replace body.get(keys) with body.keys because I want this 
	# to fail if the player does not have a keys variable
	# I also made MAXKEYS a player constant to make it easier to change
	if body.name == "Player" && body.keys < body.MAX_KEYS:
		# Pickup the key and then delete it.
		body.keys += 1
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

