class_name MantenerPulsado
extends PuzzleMinigame

## Microjuego "Mantener Pulsado": el jugador tiene que mantener presionado
## el botón, sin soltar, hasta que la barra llegue al 100%. Si lo suelta
## antes de tiempo, falla.

@export var hold_duration: float = 3.0

@onready var hold_button: Button = $HoldButton
@onready var progress_bar: ProgressBar = $ProgressBar

var _holding: bool = false
var _elapsed: float = 0.0
var _finished: bool = false
var _first_press: bool = true

func _ready() -> void:
	$Label.text = "MANTENÉ\nPULSADO"
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	hold_button.button_down.connect(_on_button_down)
	hold_button.button_up.connect(_on_button_up)

func _process(delta: float) -> void:
	if _finished or not _holding:
		return
	
	_elapsed += delta
	progress_bar.value = (_elapsed / hold_duration) * 100.0
	
	if _elapsed >= hold_duration:
		_finish(true)

func _on_button_down() -> void:
	if _finished:
		return
	_holding = true
	if _first_press:
		_first_press = false
		interacted.emit()

func _on_button_up() -> void:
	if _finished:
		return
	_holding = false
	if _elapsed < hold_duration:
		_finish(false)

func _finish(success: bool) -> void:
	_finished = true
	set_process(false)
	if success:
		solved.emit()
	else:
		failed.emit()
