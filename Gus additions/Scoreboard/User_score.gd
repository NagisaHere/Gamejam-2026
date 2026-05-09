extends TextureRect

@onready var Name := $Name
@onready var TimeLeft := $TimeLeft
@onready var FingersLeft := $FingersLeft

# Called when the node enters the scene tree for the first time.
func setup(n, t, f) -> void:
	Name.text = n
	TimeLeft.text = t
	FingersLeft.text = f
