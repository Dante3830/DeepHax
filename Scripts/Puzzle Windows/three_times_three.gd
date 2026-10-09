class_name ThreeTimesThree
extends PuzzleMinigame

@export_range(1, 9) var min_lit_cells: int = 3
@export_range(1, 9) var max_lit_cells: int = 5
@export var lit_color: Color = Color(0.2, 0.4, 1.0)

@onready var buttons: Array[Button] = [
	$Button1, $Button2, $Button3,
	$Button4, $Button5, $Button6,
	$Button7, $Button8, $Button9,
]

@onready var target_panels: Array[Panel] = [
	$Panel1, $Panel2, $Panel3,
	$Panel4, $Panel5, $Panel6,
	$Panel7, $Panel8, $Panel9,
]

var _target_pattern: Array[bool] = []
var _first_input: bool = true
var _finished: bool = false

func _ready() -> void:
	_generate_target_pattern()
	_show_target_pattern()
	
	var start_all_pressed: bool = randf() < 0.5
	for i in buttons.size():
		buttons[i].button_pressed = start_all_pressed
		buttons[i].toggled.connect(_on_button_toggled.bind(i))

func _generate_target_pattern() -> void:
	_target_pattern.resize(buttons.size())
	_target_pattern.fill(false)
	
	var lit_count: int = randi_range(min_lit_cells, max_lit_cells)
	var indices: Array[int] = []
	for i in buttons.size():
		indices.append(i)
	indices.shuffle()
	for i in lit_count:
		_target_pattern[indices[i]] = true

func _show_target_pattern() -> void:
	for i in target_panels.size():
		target_panels[i].self_modulate = lit_color if _target_pattern[i] else Color.WHITE

func _on_button_toggled(_pressed: bool, _index: int) -> void:
	if _finished:
		return
	
	if _first_input:
		_first_input = false
		interacted.emit()
	
	if _matches_target():
		_finished = true
		for button in buttons:
			button.disabled = true
		solved.emit()

func _matches_target() -> bool:
	for i in buttons.size():
		if buttons[i].button_pressed != _target_pattern[i]:
			return false
	return true
