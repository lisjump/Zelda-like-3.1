extends Node

export(String, FILE) var inital_area_path = "res://areas/dungeon.tscn"

const SAVE_FILE := "res://game-data.json"

var current_area = null
var player = "Player"
var camera = "Camera"

func _ready():
	player = get_node(player)

	yield(get_tree(), "idle_frame")
	load_game()
	
	yield(get_tree(), "idle_frame")
	if !current_area:
		current_area = instance_area(inital_area_path)
		player.position = current_area.player_start
		player.spritedir = current_area.player_start_spritedir

	camera = get_node(camera)
	camera.connect("screen_change_completed", self, "screen_change_completed")

func _process(delta):
	if Input.is_action_just_pressed("LOAD"):
		load_game()
	if Input.is_action_just_pressed("SAVE"):
		save_game()


func instance_area(path):
	var new_area = load(path)
	var new_scene = new_area.instance()
	add_child(new_scene)
	return new_scene

func teleport(new_scene_path, new_position, new_spritedir):
	get_tree().paused = true
	if current_area:
		current_area.call("save_maparea")
		current_area.queue_free()
		yield(current_area, "tree_exited")
	
	var new_area = instance_area(new_scene_path)
	player.position = new_position
	player.state = "default"
	current_area = new_area
	player.spritedir = new_spritedir
	get_tree().paused = false	

	
#------------- SIGNALS ------------------------

func screen_change_completed():
	save_game()
	
#------------- SAVING ------------------------

# Saving mechanics:
# Saving happens in three parts
# 1. Each area is saved as it is unloaded and when the whole
#    world is saved
# 2. At save game time, we save everything that is in group 
#    persist, except for the current area, which is saved separately
# 3. At save game time, we save certain extra stats, such as which is
#    the current area and where the player start position should be

#------------- save extra stats ------------------------
func save():
	var save_dict = {
		"filename" : get_filename(),
		"inital_area_path" : current_area.get_filename(),
		"player_startx" : current_area.player_start.x,
		"player_starty" : current_area.player_start.y,
		"player_start_spritedir" : current_area.player_start_spritedir
	}

	return save_dict

func load_dict(node_data):
	inital_area_path		= node_data["inital_area_path"]
	player.position.x	= node_data["player_startx"]
	player.position.y 	= node_data["player_starty"]
	if "player_start_spritedir" in node_data:
		print("yes")
		player.spritedir 	= node_data["player_start_spritedir"]

#------------- save game ------------------------

func save_game(include_area = true):
	if current_area and include_area:
		current_area.call("save_maparea")
		
	var save_game = File.new()
	save_game.open(SAVE_FILE, File.WRITE)
	
	# Save stats
	var node_data = save()
	save_game.store_line(to_json(node_data))
	
	var save_nodes = get_tree().get_nodes_in_group("persist")
	for node in save_nodes:
		if node.filename.empty():
			print("--persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue
		if node.get_parent() == current_area:
			print("--persistent node '%s' is in the current map area, skipped" % node.name)
			continue
		if !node.has_method("save"):
			print("--persistent node '%s' is missing a save() function, skipped" % node.name)
			continue

		node_data = node.call("save")
		save_game.store_line(to_json(node_data))
		
	save_game.close()

func load_game():
	var save_game = File.new()
	var local_save_data = null
	if not save_game.file_exists(SAVE_FILE):
		return # Error! We don't have a save to load.

	# We need to revert the game state so we're not cloning objects
	# during loading. This will vary wildly depending on the needs of a
	# project, so take care with this step.
	# For our example, we will accomplish this by deleting saveable objects.
	var save_nodes = get_tree().get_nodes_in_group("persist")

	for node in save_nodes:
		# if it is the player (our current) node we can't delete it
		# we also don't want to delete it if it doesn't have a save
		# function, because we probably haven't finished setting it up
		if player.get_filename() == node.get_filename():
			print("--persistent node '%s' is the Player node, skipped" % node.name)
			continue
		elif !node.has_method("save"):
			print("--persistent node '%s' is missing a save() function, skipped" % node.name)
			continue
		node.queue_free()


	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	save_game.open(SAVE_FILE, File.READ)
	while save_game.get_position() < save_game.get_len():
		# Get the saved dictionary from the next line in the save file
		var node_data = parse_json(save_game.get_line())

		if node_data == null:
			continue

		# If it is the player node we're not creating a new instance
		if player.get_filename() == node_data["filename"]:
			player.load_dict(node_data)
			continue
		
		# If it is the local file then save the line to be loaded at the
		# end.  We're not loading it now because we want to overwrite player
		# position.
		if get_filename() == node_data["filename"]:
			local_save_data = node_data
			continue

		# Firstly, we need to create the object and add it to the tree and set its position.
		var new_object = load(node_data["filename"]).instance()
		get_node(node_data["parent"]).add_child(new_object)
		new_object.position = Vector2(node_data["pos_x"], node_data["pos_y"])
		
		# If it had its own load method, use it
		# Otherwise set the remaining variables based on key names
		if new_object.has_method("load_dict"):
			new_object.load_dict(node_data)
		else:
			for i in node_data.keys():
				if i == "filename" or i == "parent" or i == "pos_x" or i == "pos_y":
					continue
				new_object.set(i, node_data[i])
				
	# load the local stats
	if local_save_data:
		load_dict(local_save_data)
		
	# load the current_area
	if inital_area_path:
		current_area = instance_area(inital_area_path)

	save_game.close()


