class_name Grid
extends PuzzleMinigame

@export var color1 := Color(0.2, 0.4, 1.0)
@export var color2 := Color(1.0, 1.0, 1.0)

@export_range(1, 9) var minSameColorPanels = 3
@export_range(1, 9) var maxSameColorPanels = 5

@onready var targetPanels = [ $Panel1, $Panel2, $Panel3, $Panel4, $Panel5, $Panel6, $Panel7, $Panel8, $Panel9 ]
@onready var buttons = [ $Button1, $Button2, $Button3, $Button4, $Button5, $Button6, $Button7, $Button8, $Button9 ]

var targetGrid = []

func _ready():
	setup_button_styles()
	generate_target_grid()
	show_target_grid()
	
	var startAllPressed: bool = randf() < 0.5
	for button in buttons:
		button.button_pressed = startAllPressed
		button.toggled.connect(on_button_toggled)
		update_button_color(button)

func generate_target_grid():
	targetGrid.resize(buttons.size())
	targetGrid.fill(false)
	
	var litCount = randi_range(minSameColorPanels, maxSameColorPanels)
	var indices: Array[int] = []
	for i in buttons.size():
		indices.append(i)
	indices.shuffle()
	for i in litCount:
		targetGrid[indices[i]] = true

func show_target_grid():
	for i in targetPanels.size():
		targetPanels[i].self_modulate = color1 if targetGrid[i] else color2

func on_button_toggled(_pressed: bool):
	notify_interaction()
	
	for button in buttons:
		update_button_color(button)
	
	if does_grid_match():
		for button in buttons:
			button.disabled = true
		finish(true)

func setup_button_styles():
	var base = StyleBoxFlat.new()
	base.bg_color = Color.WHITE
	for button in buttons:
		for state in ["normal", "pressed", "hover", "hover_pressed", "disabled"]:
			button.add_theme_stylebox_override(state, base)
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func update_button_color(button: BaseButton):
	var color = color1 if button.button_pressed else color2
	button.self_modulate = color

func does_grid_match() -> bool:
	for i in buttons.size():
		if buttons[i].button_pressed != targetGrid[i]:
			return false
	return true
