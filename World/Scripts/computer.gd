extends Node2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	$TypingHand.show_typing_state(0)
	$typing.fingers_changed.connect($CanvasLayer.set_fingers_remaining)
	$Timer.start()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	$typing._game_over()
