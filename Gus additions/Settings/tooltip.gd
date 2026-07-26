extends PanelContainer

@export var OFFSET: Vector2 = Vector2.ONE * 10.0
var opacity_tween: Tween = null

func _input(event: InputEvent) -> void:
	if visible and event is InputEventMouseMotion:
		global_position = get_global_mouse_position() + OFFSET

# Called when the node enters the scene tree for the first time.
func _ready() -> void: hide()

func toggle(on: bool):
	if opacity_tween: opacity_tween.kill()
	opacity_tween = create_tween()
	if on:
		show()
		# Fade into full visibility smoothly from its current opacity
		opacity_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	else:
		# Fade out to 0, then safely call hide() via a callback instead of 'await'
		opacity_tween.tween_property(self, "modulate:a", 0.0, 0.2)
		opacity_tween.tween_callback(hide)

	
