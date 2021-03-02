extends Camera2D

export(Vector2) var SCREEN_SIZE = Vector2.ZERO
export(float, 0, 5, .1) var SCROLL_SPEED	= 0.5
export(NodePath) var target

var target_grid_pos := Vector2(0,0)
var last_target_grid_pos := Vector2(0,0)
var camera_rect := Rect2()

signal screen_change
signal screen_change_started
signal screen_change_completed

func _ready():
	# target is set in the scene the camera lives in and is generally the player
	# setting it in the scene means not hard coding it
	target = get_node(target)
	
	if SCREEN_SIZE == Vector2.ZERO:
		SCREEN_SIZE = Vector2(ProjectSettings.get_setting("display/window/size/width"),ProjectSettings.get_setting("display/window/size/height"))
	
	# Find out which grid the target is in and 
	# move the camera to the top left corner
	target_grid_pos = get_grid_pos(target.position)
	position = target_grid_pos * SCREEN_SIZE
	last_target_grid_pos = target_grid_pos
	
	# connect some actions - a tween is a flexible animator and handles
	# our smooth screen transitions
	$Tween.connect("tween_started", self, "screen_change_started")
	$Tween.connect("tween_completed", self, "screen_change_completed")


func _process(delta):
	camera_rect = Rect2(position, SCREEN_SIZE)
	
	# Signals are a way to communitcate with other scripts in the game
	if $Tween.is_active():
		emit_signal("screen_change")
	
	# if the player is no longer in the camera rectangle
	if !$Tween.is_active() && !camera_rect.has_point(target.position):
		scroll_camera()

func scroll_camera():
	target_grid_pos = get_grid_pos(target.position)
	$Tween.interpolate_property(self, "position", last_target_grid_pos * SCREEN_SIZE, target_grid_pos * SCREEN_SIZE, SCROLL_SPEED, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	last_target_grid_pos = target_grid_pos

# find the position placement on an (x,y) grid 
func get_grid_pos(pos):
	var x = floor(pos.x / SCREEN_SIZE.x)
	var y = floor(pos.y / SCREEN_SIZE.y)
	return Vector2(x,y)

# Signals are a way to communitcate with other scripts in the game
func screen_change_started(object, nodepath):
	emit_signal("screen_change_started")

func screen_change_completed(object, nodepath):
	emit_signal("screen_change_completed")
	
func area_exited(area):
	var body = area.get_parent()
	if body.get_groups().has("projectile"):
		body.queue_free()
	if area.get_groups().has("disappears"):
		area.queue_free()

