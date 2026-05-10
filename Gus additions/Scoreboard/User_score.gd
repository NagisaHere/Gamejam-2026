extends TextureRect

@onready var Name := $Name
@onready var TimeLeft := $TimeLeft
@onready var FingersLeft := $FingersLeft

var minutes:= 0

# Called when the node enters the scene tree for the first time.
func setup(n, t, f) -> void:
	Name.text = n
	FingersLeft.text = str(f)
	
	while t > 60:
		minutes += 1
		t -= 60
		
	if t > 9 and minutes > 9:
		TimeLeft.text = str(minutes) + ":" + str(t)
	elif t > 9:
		TimeLeft.text = "0" + str(minutes) + ":" + str(t)
	elif minutes > 9:
		TimeLeft.text = str(minutes) + ":" + "0" + str(t)
	else:
		TimeLeft.text = "0" + str(minutes) + ":" + "0" + str(t)
