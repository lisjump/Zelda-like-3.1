extends StaticBody2D

export(String, MULTILINE) var text = ""

func _ready():
	add_to_group("interact")
	add_to_group("nopush")

# called from player.loop_interact
func interact(node):
	node.action_cooldown = 5
	var dialog = preload("res://ui/dialog.tscn").instance()
	if text != "":
		dialog.text = text
	get_parent().add_child(dialog)
