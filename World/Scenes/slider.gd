extends CanvasLayer

var scrollBar_tracker = []
var fullBar = ["A", "S", "D", "F", "G", "H", "J", "K", "L", "Semicolon"]
@onready var Box = $HBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# checks if the input keys follow the pattern of fullBar and updates the ProgressBar accordingly
func _process(delta: float) -> void:
	if scrollBar_tracker.size() > fullBar.size():
		reset_progressBar()
		return
	
	for letter_index in range(scrollBar_tracker.size()):
		if scrollBar_tracker[letter_index] != fullBar[letter_index]:
			reset_progressBar()
			return
			
	#percent of progress through fullBar inputted
	#make one float to avoid integer division
	var percentage_complete = float(scrollBar_tracker.size())/fullBar.size() * 100
	#print(percentage_complete)
	update_ProgressBar(percentage_complete)
	
	for button in range(scrollBar_tracker.size()):
		Box.get_child(button).button_pressed = true
	

#grabs keystrokes inputted and puts them in scrollBar_Tracker
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_echo():
			return
		var current_keycode = event.keycode
		var key_name = OS.get_keycode_string(current_keycode)
		if event.pressed:
			scrollBar_tracker.append(key_name)
			print(scrollBar_tracker)
			#everytime a keystroke is input restart the no-input timeout countdown
			$ProgressBar/Timer.start()
		else:
			return

#percentage out of 100
func update_ProgressBar(percentage: float) -> void:
	$ProgressBar.value = percentage

#timer for No-input timeout
func _on_timer_timeout() -> void:
	reset_progressBar()
	
func reset_progressBar():
	update_ProgressBar(0)
	scrollBar_tracker = []
	for button in range(fullBar.size()):
		Box.get_child(button).button_pressed =false
		
		
#when successful execute vfx e.t.c
func _on_progress_bar_bar_is_full() -> void:
	for button in range(fullBar.size()):
		var stylebox = Box.get_child(button).get_theme_stylebox("pressed")
		stylebox.border_color = Color.YELLOW
		
	var Progress_stylebox = $ProgressBar.get_theme_stylebox("fill")
	Progress_stylebox.bg_color = Color("c7cc2d")
	await get_tree().create_timer(1.0).timeout
	close_popup()
	
@onready var popup = $"."
func close_popup():
	popup.visible = false
	get_tree().paused = false
