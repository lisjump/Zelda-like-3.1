class_name pickup
extends Area2D

export(bool) var disappears = false

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered", self, "body_entered")
	connect("area_entered", self, "area_entered")
	
func area_entered(area):
	var area_parent = area.get_parent()
	if area_parent.name == "Sword":
		body_entered(area_parent.get_parent())

func body_entered(body):
	pass
