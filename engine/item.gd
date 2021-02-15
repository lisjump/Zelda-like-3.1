extends Node2D

class_name Item

# This is pretty much just here to make sure things are consistent,
# that the item is assigned the same type as its parent
# and that it is added to an item group

var TYPE = null

# input is set in entity.use_item()
var input = null

# These are settable in the inspector
# (float, min, max, interval)
export(float, 0, 20, 0.5) var		DAMAGE 			= 0.5
export(int, 1, 20) var 			MAX_AMOUNT 		= 1
export(bool) var 				delete_on_hit 	= false

func _ready():
	TYPE = get_parent().TYPE
	add_to_group("item")
