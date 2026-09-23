class_name SimonDice
extends PuzzleMinigame

# Microjuego "Simón Dice": se muestra una secuencia de colores iluminando
# el panel Light de cada botón, y el jugador tiene que repetirla en
# el mismo orden tocando los botones. Si se equivoca, falla.

@export var sequence_length: int = 4
@export var flash_duration: float = 0.6
@export var pause_between_flashes: float = 0.25
@export var reveal_duration: float = 0.3  # cuánto tarda en aparecer el tablero

# Los 4 botones clickeables
@onready var buttons: Array[Button] = [$Red, $Yellow, $Green, $Blue]

# Los paneles Light hijos de cada botón (mismo orden que buttons)
@onready var lights: Array[Panel] = [
	$Red/RedLight,
	$Yellow/YellowLight,
	$Green/GreenLight,
	$Blue/BlueLight,
]

var _sequence: Array[int] = []
var _player_index: int = 0
var _accepting_input: bool = false
var _first_input: bool = true
var _finished: bool = false

func _ready() -> void:
	# Ocultar todo hasta que arranque la presentación: botones en
	# opacidad 0 (para el fade-in) y paneles Light apagados (para
	# la secuencia de luces).
	for button in buttons:
		button.modulate.a = 0.0
	for light in lights:
		light.visible = false

	for i in buttons.size():
		buttons[i].pressed.connect(_on_button_pressed.bind(i))

	_set_buttons_disabled(true)
	_generate_sequence()

# Llamada por PuzzleWindow (ver PuzzleMinigame.start()) justo después de
# que la ventana termina de emerger: revela el tablero (fade-in de
# botones) y recién después arranca la secuencia de luces.
func start() -> void:
	await _reveal_buttons()
	await _play_sequence()

# Hace aparecer los 4 botones juntos, a la vez, con un fade-in.
func _reveal_buttons() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	for button in buttons:
		tween.tween_property(button, "modulate:a", 1.0, reveal_duration)
	await tween.finished

func _generate_sequence() -> void:
	_sequence.clear()
	for i in sequence_length:
		_sequence.append(randi() % buttons.size())

# Corrutina: muestra la secuencia completa iluminando los paneles Light
# y recién después habilita el input del jugador.
func _play_sequence() -> void:
	_accepting_input = false
	_set_buttons_disabled(true)

	await get_tree().create_timer(0.4).timeout

	for index in _sequence:
		if _finished:
			return
		await _flash_button(index)
		await get_tree().create_timer(pause_between_flashes).timeout

	if _finished:
		return

	_accepting_input = true
	_set_buttons_disabled(false)

func _flash_button(index: int) -> void:
	lights[index].visible = true
	await get_tree().create_timer(flash_duration).timeout
	lights[index].visible = false

func _set_light(index: int, lit: bool) -> void:
	lights[index].visible = lit

func _set_buttons_disabled(disabled: bool) -> void:
	for button in buttons:
		button.disabled = disabled

func _on_button_pressed(index: int) -> void:
	if _finished or not _accepting_input:
		return

	if _first_input:
		_first_input = false
		interacted.emit()

	_set_light(index, true)
	get_tree().create_timer(0.15).timeout.connect(
		func(): _set_light(index, false),
		CONNECT_ONE_SHOT
	)

	if index == _sequence[_player_index]:
		_player_index += 1
		if _player_index >= _sequence.size():
			_finish(true)
	else:
		_finish(false)

func _finish(success: bool) -> void:
	_finished = true
	_accepting_input = false
	_set_buttons_disabled(true)
	for light in lights:
		light.visible = false
	if success:
		solved.emit()
	else:
		failed.emit()
