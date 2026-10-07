class_name AjustarReloj
extends PuzzleMinigame

# Microjuego "Ajustar reloj": el jugador arrastra las 3 agujas (hora, minuto,
# segundo) hasta que coincidan con la hora digital que se muestra arriba.
# Cada aguja se "engancha" (snap) a la posición discreta más cercana mientras
# se arrastra, así no hace falta precisión de píxel perfecta.

@onready var panel: Panel = $Panel
@onready var clock_center: Node2D = $CircleA
@onready var hour_needle: Node2D = $Aguja1
@onready var minute_needle: Node2D = $Aguja2
@onready var second_needle: Node2D = $Aguja3

@onready var hours_text: Label = $HH_MM_SS/HoursText
@onready var minutes_text: Label = $HH_MM_SS/MinutesText
@onready var seconds_text: Label = $HH_MM_SS/SecondsText

var _target_hour: int = 1    # 1-12
var _target_minute: int = 0  # 0-59
var _target_second: int = 0  # 0-59

var _dragging_needle: Node2D = null
var _first_input: bool = true
var _finished: bool = false


func _ready() -> void:
	set_process(false)

	# Arrancan separadas 120° entre sí para poder agarrarlas individualmente
	# desde el principio, sin que estén las tres superpuestas en las 12.
	hour_needle.rotation = 0.0
	minute_needle.rotation = TAU / 3.0
	second_needle.rotation = 2.0 * TAU / 3.0

	_generate_target_time()
	_show_target_time()

	panel.gui_input.connect(_on_panel_gui_input)


func _generate_target_time() -> void:
	_target_hour = randi_range(1, 12)
	_target_minute = randi_range(0, 59)
	_target_second = randi_range(0, 59)


func _show_target_time() -> void:
	hours_text.text = "%02d" % _target_hour
	minutes_text.text = "%02d" % _target_minute
	seconds_text.text = "%02d" % _target_second


func _on_panel_gui_input(event: InputEvent) -> void:
	if _finished or _dragging_needle:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_start_drag(event.position)


func _start_drag(local_pos: Vector2) -> void:
	var clock_angle := _angle_from_center(local_pos)
	var candidates: Array[Node2D] = [hour_needle, minute_needle, second_needle]

	var closest: Node2D = candidates[0]
	var closest_diff: float = _angle_diff(clock_angle, closest.rotation)
	for needle in candidates:
		var diff := _angle_diff(clock_angle, needle.rotation)
		if diff < closest_diff:
			closest = needle
			closest_diff = diff

	_dragging_needle = closest
	set_process(true)

	if _first_input:
		_first_input = false
		interacted.emit()


# Corre solo mientras se arrastra una aguja. Uso _process (no gui_input) para
# el seguimiento del arrastre, así no se corta si el mouse sale del área
# del panel mientras mantenés el click.
func _process(_delta: float) -> void:
	if not _dragging_needle:
		set_process(false)
		return

	var local_mouse: Vector2 = panel.get_local_mouse_position()
	var clock_angle := _angle_from_center(local_mouse)
	var steps: int = 12 if _dragging_needle == hour_needle else 60
	_dragging_needle.rotation = _snap_angle(clock_angle, steps)

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_dragging_needle = null
		set_process(false)
		_check_solved()


func _angle_from_center(local_pos: Vector2) -> float:
	var to_point := local_pos - clock_center.position
	return fposmod(to_point.angle() + PI / 2.0, TAU)


func _snap_angle(angle: float, steps: int) -> float:
	var step_size: float = TAU / steps
	return round(angle / step_size) * step_size


func _angle_diff(a: float, b: float) -> float:
	return abs(wrapf(a - b, -PI, PI))


func _angle_to_index(angle: float, steps: int) -> int:
	var step_size: float = TAU / steps
	return int(round(fposmod(angle, TAU) / step_size)) % steps


func _check_solved() -> void:
	var hour_index := _angle_to_index(hour_needle.rotation, 12)
	var minute_index := _angle_to_index(minute_needle.rotation, 60)
	var second_index := _angle_to_index(second_needle.rotation, 60)
	var target_hour_index: int = _target_hour % 12  # 12 -> índice 0

	if hour_index == target_hour_index and minute_index == _target_minute and second_index == _target_second:
		_finished = true
		solved.emit()
