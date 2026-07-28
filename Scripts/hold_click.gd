extends Control

@onready var progress = $ProgressBar
@onready var button = $Button

func _on_button_button_down() -> void:
	progress.value += 1
	
	if progress.value == 100:
		button.text = "¡Completado!"
		$SelfDestruction.start()

func _on_self_destruction_timeout() -> void:
	self.queue_free()
