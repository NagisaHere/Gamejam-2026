extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

@onready var popup = $Panel
func toggle_popup():
	popup.visible != popup.visible
	get_tree().paused = popup.visible
	
