class_name MantenerPulsado
extends PuzzleMinigame

@export var hold_duration: float = 3.0
@onready var hold_button: Button = $HoldButton
@onready var progress_bar: ProgressBar = $ProgressBar

var start_press = true
var holding = false
var elapsed = 0.0
var finished = false

func _process(delta: float) -> void:
	if finished or !holding:
		return
	
	elapsed += delta
	progress_bar.value = (elapsed / hold_duration) * 100.0
	
	if elapsed >= hold_duration:
		finish(true)

func finish(success: bool) -> void:
	finished = true
	set_process(false)
	if success:
		solved.emit()
	else:
		failed.emit()

func _on_hold_button_button_down():
	if finished:
		return
	holding = true
	if start_press:
		start_press = false
		interacted.emit()

func _on_hold_button_button_up():
	if finished:
		return
	holding = false
	if elapsed < hold_duration:
		finish(false)
