extends CanvasLayer

onready var player = get_parent().get_node("Player")


# Number of hearts in a row
const HEART_ROW_SIZE := 8

# space between hearts (including heart width)
const HEART_OFFSET := 8

onready var hearts := $hearts
onready var keys := $keys

func _ready():
	for i in player.MAX_HEALTH:
		new_heart()		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# find the heart that might not be full.
	var last_heart = floor(player.health)
	
	for heart in hearts.get_children():
		var index = heart.get_index()
		
		# if this heart comes after the last heart, then it is empty
		# if this hear is the last heart, find the fraction
		# if this heart comes before the last heart, it is full
		if index > last_heart:
			heart.frame = 0
		elif index == last_heart:
			heart.frame = (player.health - last_heart) * 4
		elif index < last_heart:
			heart.frame = 4
			
	# update the sprite frame to be the player keys
	keys.frame = player.keys

func new_heart():
	var newheart = Sprite.new()
	newheart.texture = hearts.texture
	newheart.hframes = hearts.hframes
	hearts.add_child(newheart)
	var index = newheart.get_index()
	var x = (index % HEART_ROW_SIZE) * HEART_OFFSET
	var y = floor(index / HEART_ROW_SIZE) * HEART_OFFSET
	newheart.position = Vector2(x, y)		
	

