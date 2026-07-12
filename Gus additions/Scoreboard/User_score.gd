extends TextureRect

@onready var Name := $Name
@onready var TimeLeft := $TimeLeft
@onready var FingersLeft := $FingersLeft
@onready var LevelsCleared := $LevelsCleared
@onready var TimeLimit := $TimeLimit
var minutes:= 0

# Called when the node enters the scene tree for the first time.

func setup(n: String, t: float, f: int, levels: int, limit: float) -> void:
	Name.text = n
	FingersLeft.text = str(f)
	
	var minutes = int(t / 60)
	var seconds = fmod(t, 60.0)
	TimeLeft.text = "%02d:%05.2f" % [minutes, seconds]
	
	LevelsCleared.text = str(levels)
	minutes = int(limit / 60)
	seconds = fmod(limit, 60.0)
	TimeLimit.text = "%02d:%05.2f" % [minutes, seconds]
	
	
