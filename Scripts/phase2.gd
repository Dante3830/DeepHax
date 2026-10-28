extends Node

const PUZZLE_WINDOW_TEMPLATE = preload("res://Scenes/Puzzle-Windows/PuzzleWindowTemplate.tscn")

const KEEP_PRESSED_SCENE = preload("res://Scenes/Puzzle-Windows/KeepPressed.tscn")
const SIMON_SAYS_SCENE = preload("res://Scenes/Puzzle-Windows/SimonSays.tscn")
const GRID_SCENE = preload("res://Scenes/Puzzle-Windows/Grid.tscn")
const CLOCK_ADJUST_SCENE = preload("res://Scenes/Puzzle-Windows/ClockAdjust.tscn")
const CABLES_CONNECT_SCENE = preload("res://Scenes/Puzzle-Windows/CablesConnect.tscn")
const ZONE_SLIDER_SCENE = preload("res://Scenes/Puzzle-Windows/ZoneSlider.tscn")
const DIFFERENCE_SCENE = preload("res://Scenes/Puzzle-Windows/Difference.tscn")

const ACCELERATOR_CONDITION: PuzzleCondition = preload("res://Scenes/Window Conditions/Accelerator.tres")
const KEYBOARD_LOCK_CONDITION: PuzzleCondition = preload("res://Scenes/Window Conditions/KeyboardLock.tres")
const HACKOINS_LOOSE_CONDITION: PuzzleCondition = preload("res://Scenes/Window Conditions/HackoinsLoose.tres")

var minigames = [
	{ "scene": SIMON_SAYS_SCENE, "time_limit": 12.0 },
	{ "scene": KEEP_PRESSED_SCENE, "time_limit": 10.0 },
	{ "scene": GRID_SCENE, "time_limit": 10.0 },
	{ "scene": CLOCK_ADJUST_SCENE, "time_limit": 15.0 },
	{ "scene": CABLES_CONNECT_SCENE, "time_limit": 10.0 },
	{ "scene": ZONE_SLIDER_SCENE, "time_limit": 10.0 },
	{ "scene": DIFFERENCE_SCENE, "time_limit": 10.0 }
]

var conditions = [null, KEYBOARD_LOCK_CONDITION, ACCELERATOR_CONDITION, HACKOINS_LOOSE_CONDITION]

var linesPool = [
	"void computerMove(char *spaces, char player, char computer);",
	"while(hacking){ protect_me(hackers, viruses); destroy(barriers) }",
	"if (hackers_tracking_me == true) { return std::hide_location; }",
	"int main() { build_protection(myHostName); return 0; }",
	"void setFilter(std::vector<std::string> const &actionResults);",
	"bool buildConnect(std::string hostName, int portNumber);",
	"cell.myData = [settings objectAtIndex:indexPath.row]",
	"setFilter(std::vector<std::string> const &actionResults) {",
	"unsigned char ProtectMyAdress[<street>, <number>, <apartment>];",
	"goConnection = [[NSURLConnection alloc]",
	"UI Image *curIMG = (UIImage *)[files objectsAtIndex::QHX]",
	"[request setHTTPBody::postData, set account::protected]",
	"void checkAction(string const &theAction, int const &theRequests);",
	'#include "accountProtector.h" #define "virusDeleter.h"',
	"public: std::ostream& operator<<(std::ostream& in);",
	"Protector protector_shapes[]{prot1(12.5, 43.2), prot2(3.14, 2.71)}",
	'virtual void draw() const { std::cout << "Denied" << std::endl; }',
	"private: double get_incognitus_location()",
	"bool informations = (hackers_identities < hackers_locations)",
	"auto info_a = expose(hacker_id, hacker_lctn, hacker_creditcard)"
]

@onready var receiver = $Receiver/Label
@onready var inserter = $Inserter
@onready var timeBar: Range = $TimeBar
@onready var timeText = $TimeBar/TimeText
@onready var time: Timer = $Time
@onready var lights = $Lights.get_children()
@onready var comboText = $"UI Coins-Combo/ComboText"
@onready var hackoinsText = $"UI Coins-Combo/HackoinsText"
@onready var gameTimeText = $"UI Coins-Combo/GameTimeText"
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var camera = $Camera2D
@onready var randomArea: CollisionShape2D = $RandomArea/CollisionShape2D
@onready var autocompleteHint = $AutocompleteHint

@export var windowSpawnMin = 8.0
@export var windowSpawnMax = 12.0
@export var successTimeGet = 30.0
@export var lineTime = 0.0

var linesToType = []
var completedLines = 0
var phaseOver = false
var lineTimeLimit: float

var currentPuzzleWindow: PuzzleWindow = null
var enterBlockedTween: Tween
var autocompleteReady = false
var greedyBroken = false

func _ready():
	$TimeBar/GetTime.visible = false
	$TimeBar/LoseTime.visible = false
	time.one_shot = true
	
	var startTime = lineTime if lineTime > 0.0 else time.wait_time
	var longCord = Upgrades.has("long_cord")
	var extraTime = Upgrades.use("extra_time")
	if longCord:
		startTime += 15.0
	if extraTime:
		startTime += 10.0
	
	lineTimeLimit = startTime
	
	if !is_equal_approx(startTime, time.wait_time):
		time.start(startTime)
	
	GameManager.reset_conditions()
	GameManager.receiverLabel = receiver
	for light in lights:
		set_light_on(light, false)
	on_hackoins_changed(GameManager.hackoins, 0)
	set_combo(GameManager.linesCombo)
	GameManager.hackoins_changed.connect(on_hackoins_changed)
	var shuffled = linesPool.duplicate()
	shuffled.shuffle()
	linesToType = shuffled.slice(0, 5)
	inserter.gui_input.connect(on_inserter_gui_input)
	load_current_line()
	_schedule_next_puzzle_window()

func _process(delta: float):
	if !phaseOver:
		GameManager.gameTime += delta
		if GameManager.timeSpeed > 1.0 and time.time_left > 0:
			apply_time_penalty(delta * (GameManager.timeSpeed - 1.0))
	update_time_ui()
	update_input_color()

func update_time_ui():
	var minutes = int(GameManager.gameTime / 60.0)
	var seconds = int(GameManager.gameTime) % 60
	var miliseconds = int((GameManager.gameTime - int(GameManager.gameTime)) * 100)
	gameTimeText.text = "%02d:%02d.%02d" % [minutes, seconds, miliseconds]
	
	if phaseOver:
		return
	timeText.text = "%02d" % ceili(time.time_left)
	if time.time_left > 0:
		timeBar.value = time.time_left / lineTimeLimit * 100
	if time.time_left <= 10:
		timeText.add_theme_color_override("font_color", Color.RED)
		timeText.add_theme_color_override("font_outline_color", Color.RED)
	else:
		timeText.add_theme_color_override("font_color", Color.GREEN)
		timeText.add_theme_color_override("font_outline_color", Color.GREEN)

func update_input_color():
	var typed = inserter.text
	var expected = receiver.text
	var color = Color.WHITE
	if typed == expected and typed != "":
		color = Color.GREEN
	elif not expected.begins_with(typed):
		color = Color.RED
	inserter.add_theme_color_override("font_color", color)

func is_phase_running() -> bool:
	return is_inside_tree() and !phaseOver and time.time_left > 0.0

func _schedule_next_puzzle_window():
	if !is_phase_running():
		return
	await get_tree().create_timer(randf_range(windowSpawnMin, windowSpawnMax)).timeout
	spawn_puzzle_window()

func spawn_puzzle_window():
	if !is_phase_running():
		return
	
	if Upgrades.has("get_out") and randf() < 0.25:
		var area = get_random_area_rect()
		_schedule_next_puzzle_window()
		return
	
	var window: PuzzleWindow = PUZZLE_WINDOW_TEMPLATE.instantiate()
	add_child(window)
	currentPuzzleWindow = window
	window.global_position = pick_window_position(window)
	
	var config: Dictionary = minigames.pick_random()
	var condition: PuzzleCondition = pick_window_condition()
	
	window.solved.connect(on_puzzle_window_solved)
	window.failed.connect(on_puzzle_window_failed)
	window.closed.connect(on_puzzle_window_closed)
	window.setup(config["scene"], condition, config.get("time_limit", 10.0))
	
	if randf() < 0.4:
		window.enable_bounce(get_random_area_rect(), randf_range(70.0, 110.0))
	
	camera.trigger_shake_x()

func get_random_area_rect() -> Rect2:
	var shape := randomArea.shape as RectangleShape2D
	if shape == null:
		return get_viewport().get_visible_rect()
	var size: Vector2 = shape.size * randomArea.global_scale.abs()
	return Rect2(randomArea.global_position - size / 2.0, size)

func pick_window_position(window: PuzzleWindow) -> Vector2:
	var area: Rect2 = get_random_area_rect()
	var footprint: Rect2 = window.get_footprint()
	var freeSpace: Vector2 = (area.size - footprint.size).max(Vector2.ZERO)
	var topLeft: Vector2 = area.position + Vector2(randf() * freeSpace.x, randf() * freeSpace.y)
	return topLeft - footprint.position

func pick_window_condition() -> PuzzleCondition:
	var available = conditions.filter(
		func(c): return c == null or not GameManager.is_condition_active(c.registry_key()))
	return available.pick_random()

func on_hackoins_changed(total: int, delta: int):
	hackoinsText.text = "x" + str(total)

func on_puzzle_window_solved(_window: PuzzleWindow, hackoinReward: int):
	if Upgrades.has("greedy"):
		if greedyBroken:
			return
		hackoinReward *= 2
	GameManager.add_hackoins(hackoinReward)

func on_puzzle_window_failed(_window: PuzzleWindow, timePenalty: float):
	if Upgrades.has("greedy") and !greedyBroken:
		greedyBroken = true
		GameManager.add_hackoins(-GameManager.hackoins)
	apply_time_penalty(timePenalty)
	animationPlayer.play("LoseTime")
	camera.trigger_shake_both_exes()

func on_puzzle_window_closed(_window: PuzzleWindow):
	currentPuzzleWindow = null
	inserter.grab_focus()
	_schedule_next_puzzle_window()

func set_light_on(light: Panel, on: bool):
	var style = light.get_theme_stylebox("panel")
	style.bg_color = Color(1, 1, 1, 1) if on else Color(0, 0, 0, 1)

func load_current_line():
	if completedLines < linesToType.size():
		receiver.text = linesToType[completedLines]
	inserter.text = ""
	autocompleteReady = Upgrades.has("auto_comp") and randf() < 0.25
	autocompleteHint.visible = autocompleteReady

func set_combo(lines: int):
	GameManager.linesCombo = lines
	comboText.text = "x" + str(lines)

func on_inserter_gui_input(event: InputEvent):
	if not (event is InputEventKey and event.pressed):
		return
	
	if GameManager.is_keyboard_locked():
		inserter.accept_event()
		return
	
	if event.is_echo():
		return
	
	if event.keycode == KEY_TAB:
		inserter.accept_event()
		if autocompleteReady:
				autocompleteReady = false
				autocompleteHint.visible = false
				inserter.text = receiver.text
				inserter.set_caret_column(inserter.text.length())
	elif event.keycode == KEY_ENTER:
		inserter.accept_event()
		if is_enter_blocked():
			show_enter_blocked_feedback()
		else:
			submit_line()

func is_enter_blocked() -> bool:
	return is_instance_valid(currentPuzzleWindow)

func show_enter_blocked_feedback():
	if enterBlockedTween:
		enterBlockedTween.kill()
	inserter.modulate = Color(1.0, 0.35, 0.35)
	enterBlockedTween = create_tween()
	enterBlockedTween.tween_property(inserter, "modulate", Color.WHITE, 0.3)

func start_time(seconds: float):
	time.start(min(seconds, lineTimeLimit))

func submit_line():
	if phaseOver:
		return
	
	if inserter.text == receiver.text:
		completedLines += 1
		set_combo(GameManager.linesCombo + 1)
		start_time(time.time_left + successTimeGet)
		animationPlayer.play("GetTime")
		
		if completedLines - 1 < lights.size():
			set_light_on(lights[completedLines - 1], true)
		
		if completedLines >= linesToType.size():
			inserter.text = ""
			end_phase()
			$Victoria.show()
			animationPlayer.play("Victory")
			await get_tree().create_timer(3.0).timeout
			SceneManager.change_scene(self, "ThankYou")
		else:
			load_current_line()
	else:
		apply_time_penalty(5.0)
		if Upgrades.use("protect_combo"):
			pass
		else:
			set_combo(0)
		camera.trigger_shake_both_exes()
		animationPlayer.play("LoseTime")

func apply_time_penalty(seconds: float):
	if phaseOver:
		return
	var remaining = time.time_left - seconds
	if remaining < 0.0:
		_on_time_timeout()
	else:
		time.start(remaining)

func end_phase():
	phaseOver = true
	time.stop()
	if currentPuzzleWindow:
		currentPuzzleWindow.queue_free()
		currentPuzzleWindow = null

func _on_time_timeout():
	if phaseOver:
		return
	end_phase()
	timeText.text = "00"
	timeBar.value = 0
	$LooseScreen.show()
