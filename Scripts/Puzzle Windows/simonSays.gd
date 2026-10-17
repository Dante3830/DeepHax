class_name SimonSays
extends PuzzleMinigame

@export var sequenceLength = 2

@onready var buttons = [$Red, $Yellow, $Green, $Blue]
@onready var buttonLights = [$Red/RedLight, $Yellow/YellowLight, $Green/GreenLight, $Blue/BlueLight]

var sequence = []
var enableButtons = false
var playerInput = 0
var flashDuration = 0.5
var flashesPause = 0.1

func start():
	await start_sequence()

func _ready():
	for i in buttonLights:
		i.visible = false
	
	for i in buttons.size():
		buttons[i].pressed.connect(on_button_pressed.bind(i))
	
	disable_buttons(true)
	create_sequence()

func create_sequence():
	sequence.clear()
	for i in sequenceLength:
		sequence.append(randi() % buttons.size())

func start_sequence():
	enableButtons = false
	disable_buttons(true)
	
	await get_tree().create_timer(1.0).timeout
	
	for index in sequence:
		buttonLights[index].visible = true
		await get_tree().create_timer(flashDuration).timeout
		buttonLights[index].visible = false
		await get_tree().create_timer(flashesPause).timeout
	
	enableButtons = true
	disable_buttons(false)

func on_button_pressed(index: int):
	if not enableButtons:
		return
	
	notify_interaction()
	
	set_light(index, true)
	get_tree().create_timer(0.15).timeout.connect(func(): set_light(index, false), CONNECT_ONE_SHOT)
	
	if index == sequence[playerInput]:
		playerInput += 1
		if playerInput >= sequence.size():
			minigame_completed(true)
	else:
		minigame_completed(false)

func disable_buttons(disabled: bool):
	for button in buttons:
		button.disabled = disabled

func set_light(index: int, lit: bool):
	buttonLights[index].visible = lit

func minigame_completed(success: bool):
	enableButtons = false
	disable_buttons(true)
	for light in buttonLights:
		light.visible = false
	finish(success)
