extends CanvasLayer

var left = [
  "QuoteLeft",
  "1",
  "2",
  "3",
  "4",
  "5",
  "Tab",
  "Q",
  "W",
  "E",
  "R",
  "T",
  "CapsLock",
  "A",
  "S",
  "D",
  "F",
  "G",
  "Shift",
  "Z",
  "X",
  "C",
  "V",
  "B",
  "Ctrl",
  "Alt",
"Left",
"Down"
]
var right = [
  "6",
  "7",
  "8",
  "9",
  "0",
  "Minus",
  "Equal",
  "Backspace",
  "Y",
  "U",
  "I",
  "O",
  "P",
  "BracketLeft",
  "BracketRight",
  "BackSlash",
  "H",
  "J",
  "K",
  "L",
  "Semicolon",
  "Apostrophe",
  "Enter",
  "B",
  "N",
  "M",
  "Comma",
  "Period",
  "Slash",
  "Shift",
  "Right",
  "Up",
  "Ctrl"
]

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_echo():
			return
		var current_keycode = event.keycode
		var key_name = OS.get_keycode_string(current_keycode)
		if event.pressed:
			#print(key_name)
			if key_name in left:
				$Cat.play("left")
				$KeyboardClick.play()
			elif key_name in right:
				$Cat.play("right")
				$KeyboardClick.play()
			elif key_name == "Space":
				$Moo.play()
		else:
			return

func enable():
	self.show()
	self.process_mode = Node.PROCESS_MODE_INHERIT
	
func disable():
	self.hide()
	self.process_mode = Node.PROCESS_MODE_DISABLED
	
func _ready() -> void:
	if SaveManager.BongoCat == true:
		enable()
	else:
		disable()
