extends ProgressBar
signal bar_is_full

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	value_changed.connect(_check_if_full)

func _check_if_full(new_value: float) -> void:
	if new_value >= max_value:
		bar_is_full.emit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
