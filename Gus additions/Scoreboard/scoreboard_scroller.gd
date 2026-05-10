extends VBoxContainer

var n : String
var t : int
var f : int

var row_scene = preload("res://Gus additions/Scoreboard/scoreboard_row.tscn")

func add_new_score(n, t, f):
	var new_row = row_scene.instantiate()
	$".".add_child(new_row)
	new_row.setup(n,t,f)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
