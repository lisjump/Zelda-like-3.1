extends Entity

onready var ray = $RayCast2D

var action_cooldown = 0

func _ready():
	add_to_group("player")
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
	elif is_on_wall() && ray.is_colliding() && !ray.get_collider().is_in_group("nopush"):
		anim_switch("push")
	else:
		anim_switch("walk")
	
	if Input.is_action_just_pressed("B") && action_cooldown == 0:
		use_item(preload("res://items/sword.tscn"), "B")

func state_swing():
	anim_switch("swing")
	loop_movement()
	loop_damage()
	movedir = Vector2.ZERO

func state_hold():
	loop_controls()
	loop_movement()
	loop_damage()
	if movedir != Vector2(0,0):
		anim_switch("walk")
	else:
		anim_switch("idle")
	
	if !Input.is_action_pressed("A") && !Input.is_action_pressed("B"):
		state = "default"

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
		elif collider.is_in_group("cliff") && spritedir == "Down":
			position.y += 2
			sfx.play(preload("res://player/player_jump.wav"), 20)
			state = "fall"
