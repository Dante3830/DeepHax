class_name SimonDice
extends PuzzleMinigame

# Microjuego "Simón Dice": se muestra una secuencia de colores iluminando
# el panel de cada botón (más claro), y el jugador tiene que repetirla en
# el mismo orden tocando los botones. Si se equivoca, falla.

@export var sequence_length: int = 4
@export var flash_duration: float = 0.6
@export var pause_between_flashes: float = 0.25

@onready var buttons: Array[Button] = [$Red, $Yellow, $Green, $Blue]

# Guardamos el color original de cada botón al arrancar, así "prender" y
# "apagar" siempre vuelve exactamente al mismo color (sin ir aclarando
# de más si el microjuego se juega más de una vez).
var _base_colors: Array[Color] = []

var _sequence: Array[int] = []
var _player_index: int = 0
var _accepting_input: bool = false
var _first_input: bool = true
var _finished: bool = false

func _ready() -> void:
	for i in buttons.size():
		var style := buttons[i].get_theme_stylebox("normal")
		_base_colors.append(style.bg_color if style is StyleBoxFlat else Color.WHITE)
		buttons[i].pressed.connect(_on_button_pressed.bind(i))
	_generate_sequence()
	_play_sequence()

func _generate_sequence() -> void:
	_sequence.clear()
	for i in sequence_length:
		_sequence.append(randi() % buttons.size())

# Corrutina: muestra la secuencia completa (iluminando los paneles) y
# recién después habilita el input en los botones.
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
	_set_panel_lit(index, true)
	await get_tree().create_timer(flash_duration).timeout
	_set_panel_lit(index, false)

func _set_panel_lit(index: int, lit: bool) -> void:
	var style := buttons[index].get_theme_stylebox("normal")
	if style is StyleBoxFlat:
		style.bg_color = _base_colors[index].lightened(0.6) if lit else _base_colors[index]

func _set_buttons_disabled(disabled: bool) -> void:
	for button in buttons:
		button.disabled = disabled

func _on_button_pressed(index: int) -> void:
	if _finished or not _accepting_input:
		return

	if _first_input:
		_first_input = false
		interacted.emit()

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
	if success:
		solved.emit()
	else:
		failed.emit()
