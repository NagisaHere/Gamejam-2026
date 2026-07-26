extends ProgressBar


var dropkey_waittime = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"../RichTextLabel".text = str(dropkey_waittime) + " seconds"

@onready var timer =$"../DropKeyTimer"
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not timer.is_stopped() and timer.wait_time > 0:
		var percent = ((timer.wait_time - timer.time_left) / timer.wait_time) * 100.0
		value = percent




func _on_typing_restart_timer() -> void:
	timer.start()


func _on_typing_finger_lost() -> void:
	timer.wait_time -= 1
	dropkey_waittime -= 1
	$"../RichTextLabel".text = str(dropkey_waittime) + " seconds"
