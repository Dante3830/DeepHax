extends CanvasLayer

func _ready() -> void:
	visible = false
	get_tree().paused = false

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("Pause"):
		if get_tree().paused:
			visible = false
			get_tree().paused = false
		else:
			visible = true
			get_tree().paused = true

func _on_resume_button_pressed() -> void:
	visible = false
	get_tree().paused = false

func _on_exit_button_pressed() -> void:
	get_tree().quit()
