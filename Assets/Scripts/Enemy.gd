extends Sprite2D
@export var blue = Color("#4682b4")

@export var green = Color("#639765")
@export var red = Color("#a65455")

@onready 
var prompt = $RichTextLabel # allows access to typed steck

@onready
var prompt_text = prompt.text

func get_prompt() -> String:
	return prompt_text


func set_next_character(next_character_index: int):
	# Helper to wrap text in color tags
	var color_wrap = func(text: String, color: Color):
		return "[color=#" + color.to_html() + "]" + text + "[/color]"

	var blue_text = color_wrap.call(prompt_text.substr(0, next_character_index), blue)
	var green_text = color_wrap.call(prompt_text.substr(next_character_index, 1), green)
	var red_text = ""

	if next_character_index < prompt_text.length() - 1:
		var remaining = prompt_text.substr(next_character_index + 1)
		red_text = color_wrap.call(remaining, red)

	# In Godot 4, use the .text property directly for BBCode
	# We also replace set_center_tags with manual [center] tags
	prompt.text = "[center]" + blue_text + green_text + red_text + "[/center]"
