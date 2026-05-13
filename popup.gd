extends Node2D


func _ready():
	# Show the menu and grab focus as soon as this scene loads
	$CanvasLayer/LineEdit.grab_focus()

func _on_line_edit_text_submitted(new_text: String) -> void:
	print("User added: ", new_text)
	hide()
	
	# Create the save data using the typed name and data

	var new_user = {
		"name": new_text, 
		"time": SaveManager.temp_time, 
		"score": SaveManager.temp_score 
	}
	SaveManager.current_save.test_data.append(new_user)
	SaveManager.save_data_supabase(new_user)
	
	# happy happy very happy scene
	get_tree().change_scene_to_file("res://Scenes/veryhappy.tscn")
