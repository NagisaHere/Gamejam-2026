class_name RichTextShakeIndex
extends RichTextEffect

var bbcode = "shake_idx"

var active_index: int = -1
var shake_level: float = 0.0

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	if char_fx.range.x == active_index and shake_level > 0.0:
		var speed = 60.0
		char_fx.offset.x += sin(char_fx.elapsed_time * speed) * shake_level
		#char_fx.offset.y += cos(char_fx.elapsed_time * speed) * shake_level
	return true
