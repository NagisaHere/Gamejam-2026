extends Node2D

@onready var time_label = $CanvasTimer/Label
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	$TypingHand.show_typing_state(0)
	$typing.fingers_changed.connect($CanvasLayer.set_fingers_remaining)
	$Timer.start()
	
	
func _process(delta):
	var seconds = int($Timer.time_left)
	time_label.text = "%02d:%02d" % [seconds / 60, seconds % 60]

func _on_timer_timeout() -> void:
	$typing._game_over()
