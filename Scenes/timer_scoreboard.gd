extends RichTextLabel
signal time_over

@export var time_left_min := 5
@export var time_left_sec := 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$".".text = str(time_left_min) + ":" + str(time_left_sec)

func _on_timer_timeout() -> void:
	if time_left_min == 0 and time_left_sec == 0:
		time_over.emit()
	elif time_left_sec == 0:
		time_left_min -= 1
	else:
		time_left_sec -= 1
	
