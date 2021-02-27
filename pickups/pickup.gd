class_name pickup
extends Area2D

export(bool) var disappears = false

onready var camera := get_node("/root/Main/Camera")

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered", self, "body_entered")
	connect("area_entered", self, "area_entered")
	
func area_entered(area):
	var area_parent = area.get_parent()
	if area_parent.name == "Sword":
		body_entered(area_parent.get_parent())
	camera.connect("screen_change_started", self, "screen_change_started")

func body_entered(body):
	pass

# This allows us to have certain enemy drops disappear when we exit a room
func screen_change_started():
	set_physics_process(false)
	
	# if the pickup no longer on camera then remove it
	if disappears:
		if !camera.camera_rect.has_point(position):
			queue_free()

