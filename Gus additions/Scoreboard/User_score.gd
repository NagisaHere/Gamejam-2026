extends TextureRect

@onready var Name := $Name
@onready var TimeLeft := $TimeLeft
@onready var FingersLeft := $FingersLeft
@onready var Place := $Place
@onready var LevelsCleared := $LevelsCleared
@onready var TimeLimit := $TimeLimit

var minutes:= 0

# Called when the node enters the scene tree for the first time.
func setup(place, name, time_left, fingers_left, levels: int, limit: float) -> void:
	Name.text = name
	FingersLeft.text = str(fingers_left)
	Place.text = str(place)
	
	var minutes = int(time_left / 60)
	var seconds = fmod(time_left, 60.0)
	TimeLeft.text = "%02d:%05.2f" % [minutes, seconds]
	
	LevelsCleared.text = str(levels)
	minutes = int(limit / 60)
	seconds = fmod(limit, 60.0)
	TimeLimit.text = "%02d:%05.2f" % [minutes, seconds]
