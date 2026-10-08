extends Control

func _process(_delta: float) -> void:
	$HackoinsText.text = "Hackoins totales: " + str(GameManager.hackoins)
	
	var minutes := int(GameManager.game_time) / 60
	var seconds := int(GameManager.game_time) % 60
	var miliseconds := int((GameManager.game_time - int(GameManager.game_time)) * 100)
	
	$TimeText.text = "Tiempo: " + "%02d:%02d.%02d" % [minutes, seconds, miliseconds]

func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/Level_1.tscn")
	GameManager.new_game()

func _on_menu_button_pressed() -> void:
	get_tree().quit()
