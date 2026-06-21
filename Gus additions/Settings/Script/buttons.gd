extends Node

var button_type = null

@export var time_left = $Timer.wait_time
@export var sentences_to_win_adjusted = $typing.type.sentences_to_win

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass

func _on_easy_pressed() -> void:
	button_type = "easy"
	time_left = 180
	sentences_to_win_adjusted = 2
	
	
func _on_normal_pressed() -> void:
	button_type = "normal"
	time_left = 150
	sentences_to_win_adjusted = 3
	
	
func _on_hard_pressed() -> void:
	button_type = "hard"
	time_left = 90
	sentences_to_win_adjusted = 3
	


func _when_button_worked() -> void:
	if button_type == "easy":
		_on_easy_pressed()
		print(time_left)
		print(sentences_to_win_adjusted)
	elif button_type == "normal":
		_on_normal_pressed()
		print(time_left)
		print(sentences_to_win_adjusted)
	elif button_type == "hard":
		_on_hard_pressed()
		print(time_left)
		print(sentences_to_win_adjusted)
	
