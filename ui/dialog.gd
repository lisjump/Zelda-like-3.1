extends CanvasLayer

var text := "Bees range in size from tiny stingless bee species whose workers are less than 2 millimetres (0.08 in) long, to Megachile pluto, the largest species of leafcutter bee, whose females can attain a length of 39 millimetres (1.54 in). The most common bees in the Northern Hemisphere are the Halictidae, or sweat bees, but they are small and often mistaken for wasps or flies. Vertebrate predators of bees include birds such as be... END. But I want another"

const LINE_LENGTH	:= 38
const TEXT_SPEED		:= 0.02
const NUM_LINES		:= 2

var lines := []

signal line_end
signal advance_text

func _ready():
	# https://docs.godotengine.org/en/stable/tutorials/misc/pausing_games.html
	get_tree().paused = true
	process_string(text)
	var line = 0
	
	# while we still have lines left to write
	while line < lines.size():
		for i in range(NUM_LINES):
			write_line(line)
			# wait until recieving the signal "line end" and then resume
			# https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/gdscript_basics.html#coroutines-with-yield
			yield(self, "line_end")
			
			# if we're not on the last line
			if i < NUM_LINES - 1:
				# create a new line (carriage return, enter, \n, etc.
				$Text.newline()

			line += 1

			# if we run out of lines, exit the for loop
			if line == lines.size():
				break
		
		# wait until receiving the signal "advance text"
		# called when the player hits "B"
		yield(self, "advance_text")
		sfx.play(preload("res://ui/dialog_line.wav"), 15)
		$Text.newline()
		
	get_tree().paused = false
	queue_free()

func process_string(s):
	# if the string won't fit on one line
	if s.length() > LINE_LENGTH:
		var character = LINE_LENGTH
		
		# Start at the end of the line and work backwards until there is 
		# a space.  Character is the index of that final space.
		while s[character] != " " && character > 1:
			character -= 1
		
		# everything to the left of character gets appended as a line of text
		lines.append(s.left(character))
		
		# everything to the right of character is the remaining text
		text = text.right(character + 1)
		
		# repeat the process with the remaining text
		process_string(text)
	else:
		lines.append(text)

func write_line(l):
	var line_text = lines[l]
	
	# Add text to the text box one character at a time
	for character in lines[l]:
		$Text.text += character
		sfx.play(preload("res://ui/dialog_character.wav"), 15)
		
		var speed = TEXT_SPEED
		# speed up the text if A or B is pressed.
		# since speed is actually a timer, making it smaller makes it faster
		if Input.is_action_pressed("A") || Input.is_action_pressed("A"):
			speed = TEXT_SPEED / 2
		
		# wait until the timer has timed out
		yield(get_tree().create_timer(speed), "timeout")
	emit_signal("line_end")

func _input(event):
	if event.is_action_pressed("A") || event.is_action_pressed("B"):
		emit_signal("advance_text")
