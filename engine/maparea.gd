extends Node
class_name MapArea

var SAVE_FILE = null
export(Vector2) var player_start
export(String, "Up", "Down", "Left", "Right")	var  player_start_spritedir = "DOWN"

func _ready():
	SAVE_FILE = "res://" + name + ".json"
	# yield is need to allow the scene to finish loading
	# before loading the savefile.
	yield(get_tree(), "idle_frame")
	load_maparea()

func save_maparea():
	var save_game = File.new()
	save_game.open(SAVE_FILE, File.WRITE)
	
	var save_nodes = get_tree().get_nodes_in_group("persist")
	
	for node in save_nodes:
		if node.filename.empty():
			print("--persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue
		if !node.has_method("save"):
			print("--persistent node '%s' is missing a save() function, skipped" % node.name)
			continue
		if node.get_parent() == self:
			var node_data = node.call("save")
			save_game.store_line(to_json(node_data))
	
	save_game.close()

func load_maparea():

	var save_game = File.new()
	if not save_game.file_exists(SAVE_FILE):
		return # Error! We don't have a save to load.

	# We need to revert the game state so we're not cloning objects
	# during loading. This will vary wildly depending on the needs of a
	# project, so take care with this step.
	# For our example, we will accomplish this by deleting saveable objects.
	var save_nodes = get_tree().get_nodes_in_group("persist")
	for i in save_nodes:
		if i.get_parent() == self:
			i.queue_free()

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	save_game.open(SAVE_FILE, File.READ)
   
	while not save_game.eof_reached():
		var node_data = parse_json(save_game.get_line())
		
		if node_data == null:
			continue
		
		# Firstly, we need to create the object and add it to the tree and set its position.
		var new_object = load(node_data["filename"]).instance()
		get_node(node_data["parent"]).add_child(new_object)
		new_object.position = Vector2(node_data["pos_x"], node_data["pos_y"])
		
		# Now we set the remaining variables.
		if new_object.has_method("load_dict"):
			new_object.load_dict(node_data)
		else:
			for i in node_data.keys():
				if i == "filename" or i == "parent" or i == "pos_x" or i == "pos_y":
					continue
				new_object.set(i, node_data[i])
	
	save_game.close()
