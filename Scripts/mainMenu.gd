extends Control

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Transition.tscn")

func _on_story_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Story.tscn")

func _on_options_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Options.tscn")

func _on_credits_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Credits.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()
