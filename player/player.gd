extends Entity

# We use raycast to see what the player is colliding with
# That way we can stop pushing things that aren't meant to pe pushed
# like signs or if our shoulder is just barely hitting a wall
onready var ray = $RayCast2D

const SAVE_FILE := "res://game-data.json"


var action_cooldown := 0
var MAX_KEYS := 9
var keys := 0

func _ready():
	add_to_group("persist")
	add_to_group("player")
	ray.add_exception(hitbox)
	camera.connect("screen_change_started", self, "screen_change_started")

func _physics_process(delta):
	match state:
		"default":
			state_default()
		"swing":
			state_swing()
		"hold":
			state_hold()
		"fall":
			state_fall()
	
	if action_cooldown > 0:
		action_cooldown -= 1
		
#------------- STATES ------------------------

func state_default():
	loop_controls()
	loop_movement()
	loop_damage()
	loop_spritedir()
	loop_interact()
	
	if movedir.length() == 1:
		ray.cast_to = movedir * 8
	
	if movedir == Vector2.ZERO:
		anim_switch("idle")
	# if player is facing a wall, but not something that shouldn't have a push animation
	elif is_on_wall() && ray.is_colliding() && !(ray.get_collider().is_in_group("nopush") || ray.get_collider().get_parent().is_in_group("nopush")):
		anim_switch("push")
	else:
		anim_switch("walk")
	
	if Input.is_action_just_pressed("B") && action_cooldown == 0:
		use_item(preload("res://items/sword.tscn"), "B")

# swing the sword
func state_swing():
	anim_switch("swing")
	
	# we run the movement loop so we can take knockback
	loop_movement()
	loop_damage()
	movedir = Vector2.ZERO

# Hold the sword in front of the player this gets set in the sword scene
func state_hold():
	loop_controls()
	loop_movement()
	loop_damage()
	if movedir != Vector2.ZERO:
		anim_switch("walk")
	else:
		anim_switch("idle")
	
	if !Input.is_action_pressed("A") && !Input.is_action_pressed("B"):
		state = "default"

# for use with the cliff scene
# this basically makes it so that you keep going down until you
# are no longer colliding with a collision tile
# right now it only works in the down direction
# to fix this edit loop_interact as well
func state_fall():
	anim_switch("jump")
	position.y += 100 * get_physics_process_delta_time()
	
	$CollisionShape2D.disabled = true
	var colliding = false
	for body in hitbox.get_overlapping_bodies():
		if body is TileMap:
			colliding = true
	if !colliding:
		$CollisionShape2D.disabled = false
		sfx.play(preload("res://player/player_land.wav"), 20)
		state = "default"

#------------- LOOPS ------------------------

func loop_controls():
	movedir = Vector2.ZERO
	
	var LEFT = Input.is_action_pressed("LEFT")
	var RIGHT = Input.is_action_pressed("RIGHT")
	var UP = Input.is_action_pressed("UP")
	var DOWN = Input.is_action_pressed("DOWN")
	
	movedir.x = -int(LEFT) + int(RIGHT)
	movedir.y = -int(UP) + int(DOWN)
	
	if Input.is_action_just_pressed("LOAD"):
		load_game()
	if Input.is_action_just_pressed("SAVE"):
		save_game()


func loop_interact():
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider.is_in_group("interact") && Input.is_action_just_pressed("A") && action_cooldown == 0:
			collider.interact(self)
		elif collider.is_in_group("door"):
			collider.interact(self)
		elif collider.is_in_group("cliff") && spritedir == "Down":
			position.y += 2
			sfx.play(preload("res://player/player_jump.wav"), 20)
			state = "fall"

#------------- SIGNALS ------------------------

func screen_change_started():
	save_game()
	
#------------- SAVING ------------------------

func save():
	var save_dict = {
		"filename" : get_filename(),
		"parent" : get_parent().get_path(),
		"pos_x" : home_position.x, # Vector2 is not supported by JSON
		"pos_y" : home_position.y,
		"spritedir" : home_spritedir,
		"health" : health,
		"MAX_HEALTH" : MAX_HEALTH,
		"DAMAGE" : DAMAGE,
		"SPEED" : SPEED,
		"keys" : keys,
	}

	return save_dict

func load_dict(node_data):
	position.x		= node_data["pos_x"]
	position.y		= node_data["pos_y"]
	home_position 	= position
	spritedir		= node_data["spritedir"]
	home_spritedir	= node_data["spritedir"]
	health			= node_data["health"]
	MAX_HEALTH		= node_data["MAX_HEALTH"]
	DAMAGE			= node_data["DAMAGE"]
	SPEED			= node_data["SPEED"]
	keys				= node_data["keys"]

	
# Note: This can be called from anywhere inside the tree. This function is
# path independent.
# Go through everything in the persist category and ask them to return a
# dict of relevant variables.
func save_game():
	print("Saving Game")
	var save_game = File.new()
	save_game.open(SAVE_FILE, File.WRITE)
	var save_nodes = get_tree().get_nodes_in_group("persist")
	for node in save_nodes:
		print(str("getting data: ", node.name))
		# Check the node is an instanced scene so it can be instanced again during load.
		if node.filename.empty():
			print("--persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue

		# Check the node has a save function.
		if !node.has_method("save"):
			print("--persistent node '%s' is missing a save() function, skipped" % node.name)
			continue

		# Call the node's save function.
		var node_data = node.call("save")

		# Store the save dictionary as a new line in the save file.
		save_game.store_line(to_json(node_data))
	
	save_game.close()

func load_game():
	var save_game = File.new()
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
		if get_filename() == node.get_filename():
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
		print(node_data)

		# If it is the player node we're not creating a new instance
		if get_filename() == node_data["filename"]:
			load_dict(node_data)
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

	save_game.close()
