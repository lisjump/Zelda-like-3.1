extends pickup


func body_entered(body):
	# I replace body.get(keys) with body.keys because I want this 
	# to fail if the player does not have a keys variable
	# I also made MAXKEYS a player constant to make it easier to change
	if body.name == "Player" && body.health < body.MAX_HEALTH:
		# Pickup the key and then delete it.
		body.health += 1
		queue_free()

