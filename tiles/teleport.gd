extends Area2D

export(String, FILE) var dest_scene
export(Vector2) var dest_position
export(String, "Up", "Down", "Left", "Right")	var  dest_spritedir = "Down"

var main_scene  := "/root/Main"

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered", self, "body_entered")
	
func body_entered(body):
	if body.name == "Player":
		# Pickup the key and then delete it.
		get_node(main_scene).call("teleport", dest_scene, dest_position, dest_spritedir)
