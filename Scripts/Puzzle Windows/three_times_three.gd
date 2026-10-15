class_name ThreeTimesThree
extends PuzzleMinigame

@onready var target_panels: Array[Panel] = [ $Panel1, $Panel2, $Panel3, $Panel4, $Panel5, $Panel6, $Panel7, $Panel8, $Panel9 ]
@onready var buttons: Array[Button] = [ $Button1, $Button2, $Button3, $Button4, $Button5, $Button6, $Button7, $Button8, $Button9 ]

@export var color1 = Color(0.2, 0.4, 1.0)
@export var color2 = Color(1.0, 1.0, 1.0)

@export_range(1, 9) var min_same_color_panels = 3
@export_range(1, 9) var max_same_color_panels = 5

var target_grid: Array[bool] = []
var first_input = true
var finished = false

func _ready() -> void:
	generate_target_grid()
	show_target_grid()
	
	var start_all_pressed: bool = randf() < 0.5
	for button in buttons:
		button.button_pressed = start_all_pressed
		button.toggled.connect(on_button_toggled)

func generate_target_grid() -> void:
	target_grid.resize(buttons.size())
	target_grid.fill(false)
	
	var lit_count: int = randi_range(min_same_color_panels, max_same_color_panels)
	var indices: Array[int] = []
	for i in buttons.size():
		indices.append(i)
	indices.shuffle()
	for i in lit_count:
		target_grid[indices[i]] = true

func show_target_grid() -> void:
	for i in target_panels.size():
		target_panels[i].self_modulate = color1 if target_grid[i] else color2

func on_button_toggled(_pressed: bool):
	if finished:
		return
	
	if first_input:
		first_input = false
		interacted.emit()
	
	if matches_target():
		finished = true
		for button in buttons:
			button.disabled = true
		solved.emit()

func matches_target() -> bool:
	for i in buttons.size():
		if buttons[i].button_pressed != target_grid[i]:
			return false
	return true
