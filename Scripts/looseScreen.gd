extends Control

func _process(_delta: float):
	$HackoinsText.text = "Hackoins totales: " + str(GameManager.totalHackoins)
	
	var minutes = float(GameManager.gameTime) / 60
	var seconds = int(GameManager.gameTime) % 60
	var miliseconds = int((GameManager.gameTime - int(GameManager.gameTime)) * 100)
	
	$TimeText.text = "Tiempo: " + "%02d:%02d.%02d" % [minutes, seconds, miliseconds]

func _on_restart_button_pressed():
	GameManager.new_game()
	SceneManager.change_scene(self, "Phases/Intro")

func _on_menu_button_pressed():
	get_tree().quit()
