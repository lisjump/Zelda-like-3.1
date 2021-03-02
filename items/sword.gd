extends Item

onready var anim := $AnimationPlayer

func _ready():
	set_physics_process(false)

func start():
	anim.connect("animation_finished", self, "destroy")
	anim.play(str("swing", get_parent().spritedir))
	sfx.play(load(str("res://items/sword_swing",int(rand_range(1,5)),".wav")))
	if get_parent().has_method("state_swing"):
		get_parent().state = "swing"

func destroy(animation):
	if input != null && Input.is_action_pressed(input):
		# if the input is still being held down turn on physics_process
		# move the sword to the correct position
		# the rest will be handled in physics process
		set_physics_process(true)
		match get_parent().spritedir:
			"Left":
				position.x += 3
			"Right":
				position.x -= 3
			"Up":
				position.y += 4
				z_index -= 1
			"Down":
				position.y -= 3
		
		# delete_on_hit is used in the entity.loop_damage		
		delete_on_hit = true
		if get_parent().has_method("state_hold"):
			get_parent().state = "hold"
			
		# return keeps us from running delete()
		return
	
	delete()

func delete():
	# set the parent state back to default from "swing"
	get_parent().state = "default"
	queue_free()

func _physics_process(delta):
	# if the input has stopped being held destroy the sword
	if !Input.is_action_pressed(input):
		destroy(null) 
	if get_parent().state == "default":
		queue_free()

