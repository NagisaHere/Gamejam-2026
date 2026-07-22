extends TextureButton

@export var normal_color:Color = Color("ffffff")
@export var hover_color:Color = Color("bfbfbfff")
@export var pressed_color:Color = Color("303030")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self_modulate = normal_color
	
	mouse_entered.connect(on_mouse_enter)
	mouse_exited.connect(on_mouse_exit)
	button_up.connect(on_button_up)
	button_down.connect(on_button_down)


func on_mouse_enter():
	self_modulate = hover_color

func on_mouse_exit():
	self_modulate = normal_color
	
func on_button_down():
	self_modulate = pressed_color
	
func on_button_up():
	await get_tree().create_timer(0.07).timeout
	self_modulate = hover_color if  is_hovered() else normal_color
