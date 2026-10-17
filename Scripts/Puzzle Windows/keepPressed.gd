class_name KeepPressed
extends PuzzleMinigame

@export var holdDuration = 3.0

@onready var progressBar = $ProgressBar

var holding = false
var elapsed = 0.0

func _process(delta: float):
	if not holding:
		return
	
	elapsed += delta
	progressBar.value = (elapsed / holdDuration) * 100.0
	
	if elapsed >= holdDuration:
		finish(true)

func _on_hold_button_button_down():
	holding = true
	notify_interaction()

func _on_hold_button_button_up():
	holding = false
	if elapsed < holdDuration:
		finish(false)
