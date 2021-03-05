extends KinematicBody2D

class_name Entity

# ATTRIBUTES
# These are settable in the inspector
export(String, "ENEMY", "PLAYER")	var TYPE 		= "ENEMY"
export(String, FILE) 			var HURT_SOUND 	= "res://enemies/enemy_hurt.wav"

# STATS
# (float, min, max, increment)
export(float, 0.5, 20, 0.5) 		var MAX_HEALTH 	= 1
export(int) 						var SPEED 		= 70
export(float, 0, 20, 0.5) 		var DAMAGE 		= 0.5


# ITEM DROPS
export(int, 0, 100, 5) 			var ITEM_DROP_PERCENT 		= 25

# Keys are scene path names and values should be integers
export(Dictionary) 				var ITEM_DROP_WEIGHTS = {
	'pickups/heart'	: 1,
	'pickups/key'	: 0,
}


# MOVEMENT
var movedir := Vector2.ZERO
var knockdir := Vector2.ZERO
var spritedir := "Down"

# COMBAT
var health : float = MAX_HEALTH
var hitstun := 0
var state := "default"
var home_position := Vector2.ZERO

# TEXTURES
var texture_default = null
var texture_hurt = null

# These get loaded a moment after the entity
onready var anim := $AnimationPlayer
onready var sprite := $Sprite
onready var hitbox := $Hitbox
onready var camera := get_node("/root/Main/Camera")

func _ready():
	texture_default = sprite.texture
	texture_hurt = load(sprite.texture.get_path().replace(".png","_hurt.png"))
	add_to_group("entity")
	health = MAX_HEALTH
	home_position = position
	
	normalize_item_drop_weights()
	
	# the camera sends these signals
	camera.connect("screen_change_started", self, "screen_change_started")
	camera.connect("screen_change_completed", self, "screen_change_completed")

func loop_movement():
	var motion
	if hitstun == 0:
		motion = movedir.normalized() * SPEED
	else:
		motion = knockdir.normalized() * 125
	move_and_slide(motion)

func loop_spritedir():
	match movedir:
		Vector2.LEFT:
			spritedir = "Left"
		Vector2.RIGHT:
			spritedir = "Right"
		Vector2.UP:
			spritedir = "Up"
		Vector2.DOWN:
			spritedir = "Down"
	# This is a unary if statement.  sprite.flip_h is  set to the 
	# return of spritedir == "Left" (true or false)
	# This lets us not need separate anims for left and right
	sprite.flip_h = spritedir == "Left"

func loop_damage():
	health = min(health, MAX_HEALTH)
	
	if hitstun > 0:
		hitstun -= 1
		sprite.texture = texture_hurt
	else:
		sprite.texture = texture_default
		if TYPE == "ENEMY" && health <= 0:
			enemy_death()
	
	for area in hitbox.get_overlapping_areas():
		var body = area.get_parent()
		
		# if the entity isn't in hitstun, and the overlapping body gives damage
		# and the overlapping body is of a different type
		if hitstun == 0 && body.get("DAMAGE") && body.get("DAMAGE") > 0 && body.get("TYPE") != TYPE:
			health -= body.DAMAGE
			hitstun = 10
			knockdir = global_position - body.global_position
			sfx.play(load(HURT_SOUND))
			
			if body.get("delete_on_hit") == true:
				body.delete()

func anim_switch(animation):
	var newanim = str(animation,spritedir)
	
	# if sprite dir is Left or Right
	if spritedir in ["Left","Right"]:
		newanim = str(animation,"Side")
	if anim.current_animation != newanim:
		anim.play(newanim)

func use_item(item, input):
	var newitem = item.instance()
	var itemgroup = str(item,self)
	newitem.add_to_group(itemgroup)
	add_child(newitem)
	if get_tree().get_nodes_in_group(itemgroup).size() > newitem.MAX_AMOUNT:
		newitem.queue_free()
		return
	newitem.input = input
	newitem.start()

func instance_scene(scene):
	var new_scene = scene.instance()
	new_scene.global_position = global_position
	get_parent().add_child(new_scene)

func enemy_death():
	instance_scene(preload("res://enemies/enemy_death.tscn"))
	enemy_drop()
	queue_free()

# When the enemy dies it may drop an item
func enemy_drop():
	# drop is a number between 0 and 99
	var drop = randi() % 100
	
	# if drop is strictly less than our percentage, then drop something
	if drop < ITEM_DROP_PERCENT:
		# Here we are basically filling a hat with names.
		# For each key, we'll put [value] entries of the key into the list
		var drop_list = []
		for key in ITEM_DROP_WEIGHTS:
			for i in range(ITEM_DROP_WEIGHTS[key]):
				drop_list.append(key)
		
		# index is a number between 0 and list size - 1
		var index = randi() % drop_list.size()
		# load the scene at index
		var scene = str("res://", drop_list[index], ".tscn")
		instance_scene(load(scene))

func screen_change_started():
	set_physics_process(false)
	
	# if the entity is an entity and no longer on camera then reset it
	if TYPE == "ENEMY":
		if !camera.camera_rect.has_point(position):
			reset()

func screen_change_completed():
	set_physics_process(true)
	
	# If the entity is an enemy and not on camera don't run physics_process
	if TYPE == "ENEMY":
		if !camera.camera_rect.has_point(position):
			set_physics_process(false)

# creates a new identical entity with it's original position
# deletes the current entity
# this also resets health
func reset():
	var new_instance = load(filename).instance()
	get_parent().add_child(new_instance)
	new_instance.position = home_position
	new_instance.home_position = home_position
	new_instance.set_physics_process(false)
	queue_free()

# With the way we handle item drops, we don't want to have the total 
# number get too big.  This keeps it below or around 100.
func normalize_item_drop_weights():
	var sum = 0
	# force multiplier to be a float
	var multiplier = 1.0
	for key in ITEM_DROP_WEIGHTS:
		sum += round(ITEM_DROP_WEIGHTS[key])
	# if our sum is greater than 100 then we want then find the 
	# multiplier that will bring it close to 100
	if sum > 100:
		multiplier = 100/sum
	
	for key in ITEM_DROP_WEIGHTS:
		# First do the multiplier
		ITEM_DROP_WEIGHTS[key] = multiplier * float(ITEM_DROP_WEIGHTS[key])
		# if rounding it will make it zero (i.e. it was .4) then make it 1
		if ITEM_DROP_WEIGHTS[key] > 0 && round(ITEM_DROP_WEIGHTS[key]) == 0:
			ITEM_DROP_WEIGHTS[key] = 1
		else:
			ITEM_DROP_WEIGHTS[key] = round(ITEM_DROP_WEIGHTS[key])


# put into helper script pls
static func rand_direction():
	var new_direction = randi() % 4
	match new_direction:
		0:
			return Vector2.LEFT
		1:
			return Vector2.RIGHT
		2:
			return Vector2.UP
		3:
			return Vector2.DOWN

