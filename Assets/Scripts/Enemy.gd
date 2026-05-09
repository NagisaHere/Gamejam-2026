extends Sprite2D 
@export var blue = Color("#4682b4") 
@export var green = Color("#639765") 
@export var red = Color("#a65455") 
@export var orange = Color("9901efff") 
@onready var prompt = $RichTextLabel # allows access to typed steck 
@onready var prompt_text = prompt.text 

func get_prompt() -> String: 
	return prompt_text 

func set_prompt(new_text: String):
	prompt_text = new_text
	prompt.text = "[center]" + new_text + "[/center]"
	

func set_next_character(next_character_index: int, mistakes: String = "", highlight_orange: bool = false):
	var color_wrap = func(text: String, color: Color):
		return "[color=#" + color.to_html() + "]" + text + "[/color]"

	var blue_text = color_wrap.call(prompt_text.substr(0, next_character_index), blue)
	var mistake_text = color_wrap.call("[u]" + mistakes + "[/u]", red)

	var next_color = orange if highlight_orange else green

	var next_text = ""
	if mistakes.length() == 0:
		next_text = color_wrap.call(prompt_text.substr(next_character_index, 1), next_color)

	var remaining_start = next_character_index + (1 if mistakes.length() == 0 else 0)
	var red_text = prompt_text.substr(remaining_start)

	prompt.text = "[center]" + blue_text + mistake_text + next_text + red_text + "[/center]"
	
