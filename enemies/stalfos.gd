extends Entity

var movetimer_length := 15
var movetimer := 0

func _ready():
	MAX_HEALTH = 1
	health = 1
	SPEED = 20
	movedir = rand_direction()
	if anim.current_animation != "default":
		anim.play("default")

func _physics_process(delta):
	loop_movement()
	loop_damage()	
	
	if movetimer > 0:
		movetimer -= 1
	if movetimer == 0 || is_on_wall():
		movedir = rand_direction()
		movetimer = movetimer_length
