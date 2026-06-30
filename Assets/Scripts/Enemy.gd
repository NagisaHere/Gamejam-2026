extends Sprite2D 
@export var blue = Color("#4682b4") 
@export var green = Color("#639765") 
@export var red = Color("#a65455") 
@export var orange = Color("9901efff") 
@onready var prompt = $RichTextLabel # allows access to typed steck 
@onready var prompt_text = prompt.text 
var shake_effect = preload("res://World/Scenes/shake_char_effect.gd").new()
var shake_tween: Tween

func _ready() -> void:
	if prompt == null:
		push_error("Could not find RichTextLabel! Check your node path.")
		return
	prompt.install_effect(shake_effect)
	
func trigger_dropkey_shake(index: int) -> void:
	if shake_tween:
		shake_tween.kill()
	print(prompt_text[index])
	
	# Set which letter index should receive the shake
	shake_effect.active_index = index
	shake_tween = create_tween()
	
	# Snap to full shake displacement, then tween it smoothly down to 0
	shake_effect.shake_level = 12.0 
	shake_tween.tween_property(shake_effect, "shake_level", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
func get_prompt() -> String: 
	return prompt_text 

func set_prompt(new_text: String):
	prompt_text = new_text
	prompt.text = "[center]" + new_text + "[/center]"
	

func set_next_character(next_character_index: int, mistakes: String = "", highlight_orange: bool = false):
	var color_wrap = func(text: String, color: Color):
		return "[shake_idx][color=#" + color.to_html() + "]" + text + "[/color][/shake_idx]"

	var blue_text = color_wrap.call(prompt_text.substr(0, next_character_index), blue)
	var mistake_text = color_wrap.call("[u]" + mistakes + "[/u]", red)

	var next_color = orange if highlight_orange else green

	var next_text = ""
	if mistakes.length() == 0:
		next_text = color_wrap.call(prompt_text.substr(next_character_index, 1), next_color)

	var remaining_start = next_character_index + (1 if mistakes.length() == 0 else 0)
	var red_text = prompt_text.substr(remaining_start)

	prompt.text = "[center]" + blue_text + mistake_text + next_text + red_text + "[/center]"
	
