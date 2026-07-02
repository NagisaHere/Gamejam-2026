extends TextureRect

@export var freeze_duration = 10.0
@export var max_ice_scale = Vector2(1.4, 1.4)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	pivot_offset = size/2.0
	start_ice_freeze()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func start_ice_freeze():
	var tween = create_tween()
	tween.tween_property(self, "scale", max_ice_scale, freeze_duration).set_trans(Tween.TRANS_LINEAR).from(Vector2(1.3, 1.3))
