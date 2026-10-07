extends Control

func _process(delta: float) -> void:
	$HackoinsText.text = "Hackoins totales: " + str(GameManager.hackoins)
	$TimeText.text = "Tiempo: " + str(GameManager.total_time)

func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/Level_1.tscn")
	GameManager.new_game()

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
