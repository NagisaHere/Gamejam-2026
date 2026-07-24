extends CanvasLayer

var zone1 = ["Shift", "Ctrl", "Alt"]
var zone2 = [
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", 
	"N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
]
var zone3 = ["0","1","2","3","4","5","6","7","8","9"]

var scrollBar_tracker = []
var fullBar = []

@onready var Box = $Buttons.get_children()

func _ready() -> void:
	pass
	
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_UNPAUSED and visible:
		fullBar.append(zone1.pick_random())
		zone2.shuffle()
		fullBar.append(zone2[0])
		fullBar.append(zone2[1])
		fullBar.append(zone3.pick_random())
	
		fullBar.shuffle()
		$Buttons/Button.text = fullBar[0]
		$Buttons/Button2.text = fullBar[1]
		$Buttons/Button3.text = fullBar[2]
		$Buttons/Button4.text = fullBar[3]

# checks if the input keys follow the pattern of fullBar and updates the ProgressBar accordingly
func _process(delta: float) -> void:
	for character in fullBar:
		for button in Box:
			if button.text == character:
				
				if character not in scrollBar_tracker:
					button.button_pressed =false
				else:
					button.button_pressed = true
	
	for character in fullBar:
		if character not in scrollBar_tracker:
			return
	await get_tree().create_timer(0.5).timeout
	close_popup()
	
	

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
		else:
			scrollBar_tracker.erase(key_name)
	
	
	
@onready var popup = $"."
func close_popup():
	if popup.visible == false:
		return
	$"../PopUp_close".play()
	popup.visible = false
	get_tree().paused = false
