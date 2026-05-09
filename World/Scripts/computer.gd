extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	$TypingHand.show_state(randi_range(0, 10))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
