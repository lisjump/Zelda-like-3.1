extends StaticBody2D


# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("nopush")
	add_to_group("door")
	
func interact(node):
	# I node.keys instead of node.get(keys) with because I want this 
	# to fail if the player does not have a keys variable
	if node.keys > 0:
		# Use a key and then delete the door.
		node.keys -= 1
		queue_free()
