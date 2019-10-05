extends Entity

func _physics_process(delta):
	match state:
		"default":
			state_default()
		"swing":
			state_swing()
		"hold":
			state_hold()
		"jump":
			state_jump()
		"fall":
			state_fall()
		"jumphold":
			state_jumphold()

func state_default():
	loop_controls()
	loop_movement()
	loop_damage()
	loop_spritedir()
	loop_height()
	
	if movedir == Vector2.ZERO:
		anim_switch("idle")
	elif is_on_wall():
		if spritedir == "Left" and test_move(transform, Vector2.LEFT):
			anim_switch("push")
		elif spritedir == "Right" and test_move(transform, Vector2.RIGHT):
			anim_switch("push")
		elif spritedir == "Up" and test_move(transform, Vector2.UP):
			anim_switch("push")
		elif spritedir == "Down" and test_move(transform, Vector2.DOWN):
			anim_switch("push")
		else:
			anim_switch("walk")
	else:
		anim_switch("walk")
	
	if Input.is_action_just_pressed("B"):
		use_item(preload("res://items/sword.tscn"), "B")

func state_swing():
	anim_switch("swing")
	loop_movement()
	loop_damage()
	loop_height()
	if height == 0:
		movedir = Vector2.ZERO
	else:
		if height < JUMP_HEIGHT:
			height += JUMP_SPEED
		else:
			height -= JUMP_SPEED

func state_hold():
	loop_controls()
	loop_movement()
	loop_damage()
	loop_height()
	if movedir != Vector2(0,0):
		anim_switch("walk")
	else:
		anim_switch("idle")
	
	if !Input.is_action_pressed("A") && !Input.is_action_pressed("B"):
		state = "default"

func state_jumphold():
	loop_controls()
	loop_movement()
	loop_damage()
	loop_height()
	anim_switch("idle")
	
	if height < JUMP_HEIGHT:
		height += JUMP_SPEED
	else:
		height -= JUMP_SPEED
	
	if !Input.is_action_pressed("A") && !Input.is_action_pressed("B"):
		state = "default"

func state_jump():
	loop_controls()
	loop_movement()
	loop_height()
	anim_switch("jump")
	height += JUMP_SPEED
	
	if Input.is_action_just_pressed("B"):
		use_item(preload("res://items/sword.tscn"), "B")
	
	if height >= JUMP_HEIGHT:
		state = "fall"

func state_fall():
	loop_controls()
	loop_movement()
	loop_height()
	anim_switch("jump")
	
	if Input.is_action_just_pressed("B"):
		use_item(preload("res://items/sword.tscn"), "B")
	
	if height <= 0:
		height = 0
		state = "default"

func loop_controls():
	movedir = Vector2.ZERO
	
	var LEFT = Input.is_action_pressed("LEFT")
	var RIGHT = Input.is_action_pressed("RIGHT")
	var UP = Input.is_action_pressed("UP")
	var DOWN = Input.is_action_pressed("DOWN")
	
	movedir.x = -int(LEFT) + int(RIGHT)
	movedir.y = -int(UP) + int(DOWN)