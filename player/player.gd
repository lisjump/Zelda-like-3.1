extends Entity

# We use raycast to see what the player is colliding with
# That way we can stop pushing things that aren't meant to pe pushed
# like signs or if our shoulder is just barely hitting a wall
onready var ray = $RayCast2D

var action_cooldown := 0
var MAX_KEYS := 9
var keys := 0

func _ready():
	add_to_group("persist")
	add_to_group("player")
	if !TYPE:
		TYPE == "PLAYER"
	ray.add_exception(hitbox)

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

#------------- SAVING ------------------------

func save():
	var save_dict = {
		"filename" : get_filename(),
		"parent" : get_parent().get_path(),
		"health" : health,
		"MAX_HEALTH" : MAX_HEALTH,
		"DAMAGE" : DAMAGE,
		"SPEED" : SPEED,
		"keys" : keys,
	}

	return save_dict

func load_dict(node_data):
	health			= node_data["health"]
	MAX_HEALTH		= node_data["MAX_HEALTH"]
	DAMAGE			= node_data["DAMAGE"]
	SPEED			= node_data["SPEED"]
	keys				= node_data["keys"]

	
