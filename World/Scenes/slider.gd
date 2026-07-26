extends CanvasLayer

var scrollBar_tracker = []
var fullBar = []

var Bar1 = ["A", "S", "D", "F", "G", "H", "J", "K", "L", "Semicolon"]
var Bar2 = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
var Bar3 = ["Z", "X", "C", "V", "B", "N", "M", "Comma", "Period", "Slash"]
var Bars = [Bar1,Bar2,Bar3]
var finished = false

@onready var Box = $HBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	finished = false

func _notification(what: int) -> void:
	if not is_node_ready():
		await ready
	if what == NOTIFICATION_PAUSED and visible:
		close_popup()
	if what == NOTIFICATION_UNPAUSED and visible:
		scrollBar_tracker = []
		fullBar = Bars.pick_random()
		for button_index in range(fullBar.size()):
			print("button index")
			print(button_index)
			match (fullBar[button_index]):
				"Semicolon":
					Box.get_child(button_index).text = ";"
				"Comma":
					Box.get_child(button_index).text = ","
				"Period":
					Box.get_child(button_index).text = "."
				"Slash":
					Box.get_child(button_index).text = "/"
				_:
					Box.get_child(button_index).text = fullBar[button_index]
				
		


# checks if the input keys follow the pattern of fullBar and updates the ProgressBar accordingly
func _process(delta: float) -> void:
	if visible == false:
		return
		
	if scrollBar_tracker.size() > fullBar.size():
		if finished == true:
				return
		reset_progressBar()
		return
	
	for letter_index in range(scrollBar_tracker.size()):
		if scrollBar_tracker[letter_index] != fullBar[letter_index]:
			if finished == true:
				return
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
	if visible == false:
		return
	if event is InputEventKey:
		if event.is_echo():
			return
		var current_keycode = event.keycode
		var key_name = OS.get_keycode_string(current_keycode)
		if event.pressed:
			scrollBar_tracker.append(key_name)
			if key_name in fullBar and visible:
				$AudioStreamPlayer.play()
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
	if finished == true:
		return
	reset_progressBar()
	
func reset_progressBar():
	update_ProgressBar(0)
	scrollBar_tracker = []
	for button in range(fullBar.size()):
		Box.get_child(button).button_pressed =false
		
		
#when successful execute vfx e.t.c
func _on_progress_bar_bar_is_full() -> void:
	finished = true
	for button in range(fullBar.size()):
		var stylebox = Box.get_child(button).get_theme_stylebox("pressed")
		stylebox.border_color = Color.YELLOW
		
	var Progress_stylebox = $ProgressBar.get_theme_stylebox("fill")
	Progress_stylebox.bg_color = Color("c7cc2d")
	await get_tree().create_timer(0.5).timeout
	close_popup()
	
@onready var popup = $"."
func close_popup():
	if popup.visible == false:
		return
	$"../PopUp_close".play()
	popup.visible = false
	get_tree().paused = false
