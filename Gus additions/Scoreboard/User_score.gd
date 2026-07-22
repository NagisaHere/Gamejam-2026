extends TextureRect

@onready var Name := $Name
@onready var TimeLeft := $TimeLeft
@onready var FingersLeft := $FingersLeft
@onready var Place := $Place

var minutes:= 0

# Called when the node enters the scene tree for the first time.
func setup(p, n, t, f) -> void:
	Name.text = n
	FingersLeft.text = str(f)
	Place.text = str(p)
	
	var minutes = int(t / 60)
	var seconds = fmod(t, 60.0)
	TimeLeft.text = "%02d:%05.2f" % [minutes, seconds]
