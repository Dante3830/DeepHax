class_name SimonDice
extends PuzzleMinigame

@export var sequence_length = 2

@onready var buttons = [$Red, $Yellow, $Green, $Blue]
@onready var button_lights = [$Red/RedLight, $Yellow/YellowLight, $Green/GreenLight, $Blue/BlueLight]

var sequence = []
var player_input = 0
var enable_input = false
var first_input = true
var flash_duration = 0.5
var flashes_pause = 0.1

func start():
	await play_sequence()

func _ready():
	for button in buttons:
		var normal_style = button.get_theme_stylebox("normal")
		if normal_style is StyleBoxFlat:
			var dimmed: StyleBoxFlat = normal_style.duplicate()
			dimmed.bg_color = normal_style.bg_color.darkened(0.35)
			button.add_theme_stylebox_override("disabled", dimmed)
	
	for button in buttons:
		button.modulate.a = 0.5
	for light in button_lights:
		light.visible = false
	
	for i in buttons.size():
		buttons[i].pressed.connect(on_button_pressed.bind(i))
	
	disable_buttons(true)
	create_sequence()

func create_sequence():
	sequence.clear()
	for i in sequence_length:
		sequence.append(randi() % buttons.size())

func play_sequence():
	enable_input = false
	disable_buttons(true)
	
	await get_tree().create_timer(1.0).timeout
	
	for index in sequence:
		if finished:
			return
		await flash_button(index)
		await get_tree().create_timer(flashes_pause).timeout
	
	if finished:
		return
	
	enable_input = true
	disable_buttons(false)
	
	for button in buttons:
		button.modulate.a = 1.0

func on_button_pressed(index: int):
	if finished or !enable_input:
		return
	
	if first_input:
		first_input = false
		interacted.emit()
	
	set_light(index, true)
	get_tree().create_timer(0.15).timeout.connect(func(): set_light(index, false), CONNECT_ONE_SHOT)
	
	if index == sequence[player_input]:
		player_input += 1
		if player_input >= sequence.size():
			finish(true)
	else:
		finish(false)

func finish(success: bool):
	enable_input = false
	disable_buttons(true)
	for light in button_lights:
		light.visible = false
	if success:
		solved.emit()
	else:
		failed.emit()

func disable_buttons(disabled: bool):
	for button in buttons:
		button.disabled = disabled

func flash_button(index: int):
	button_lights[index].visible = true
	await get_tree().create_timer(flash_duration).timeout
	button_lights[index].visible = false

func set_light(index: int, lit: bool):
	button_lights[index].visible = lit
