extends Node

const PUZZLE_WINDOW_SCENE = preload("res://Scenes/Puzzle-Windows/PuzzleWindowTemplate.tscn")

# Microjuegos
const KEEP_PRESSED_SCENE = preload("res://Scenes/Puzzle-Windows/KeepPressed.tscn")
const SIMON_SAYS_SCENE = preload("res://Scenes/Puzzle-Windows/SimonSays.tscn")
const THREE_TIMES_THREE_SCENE = preload("res://Scenes/Puzzle-Windows/ThreeTimesThree.tscn")
const CLOCK_ADJUST_SCENE = preload("res://Scenes/Puzzle-Windows/ClockAdjust.tscn")
const CABLES_CONNECT_SCENE = preload("res://Scenes/Puzzle-Windows/CablesConnect.tscn")

# Condicionadores
const ACCELERATOR_CONDITION: PuzzleCondition = preload("res://Scenes/Window Conditions/Accelerator.tres")
const KEYBOARD_LOCK_CONDITION: PuzzleCondition = preload("res://Scenes/Window Conditions/KeyboardLock.tres")

const LINES_PER_PHASE = 5
const WRONG_LINE_PENALTY = 5.0

const WINDOW_SPAWN_MIN = 8.0
const WINDOW_SPAWN_MAX = 12.0

const MOVING_WINDOW_CHANCE = 0.35
const MOVING_WINDOW_SPEED_MIN = 70.0
const MOVING_WINDOW_SPEED_MAX = 110.0

@export var success_time_get = 30.0

var phase1_minigames = [
	{ "scene": SIMON_SAYS_SCENE, "time_limit": 12.0 },
	{ "scene": KEEP_PRESSED_SCENE, "time_limit": 10.0 },
	{ "scene": THREE_TIMES_THREE_SCENE, "time_limit": 10.0 },
	{ "scene": CLOCK_ADJUST_SCENE, "time_limit": 15.0 },
	{ "scene": CABLES_CONNECT_SCENE, "time_limit": 10.0 }
]

var phase1_conditions = [null, KEYBOARD_LOCK_CONDITION, ACCELERATOR_CONDITION]

var lines_pool = [
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
	"public: std::ostream& operator<<(std::ostream& in, std::ostream& out);",
	"Protector protector_shapes[]{prot1(12.5, 43.2), prot2(3.14, 2.71)}",
	'virtual void draw() const { std::cout << "Access denied" << std::endl; }',
	"private: double get_incognitus_location()",
	"bool informations = (hackers_identities < hackers_locations)",
	"auto info_a = expose(hacker_id, hacker_lctn, hacker_creditcard)"
]

var lines_to_type = []
var completed_lines = 0
var phase_over = false
var line_time_limit: float

var _current_puzzle_window: PuzzleWindow = null

@onready var receiver = $Receiver/Label
@onready var inserter = $Inserter
@onready var time_bar: Range = $TimeBar
@onready var time_text = $TimeBar/TimeText
@onready var time: Timer = $Time

@onready var lights = $Lights.get_children()

@onready var combo_text = $"UI Coins-Combo/ComboText"
@onready var hackoins_text = $"UI Coins-Combo/HackoinsText"
@onready var game_time_text = $"UI Coins-Combo/GameTimeText"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera = $Camera2D
@onready var random_area: CollisionShape2D = $RandomArea/CollisionShape2D

#region LIFECYCLE METHODS
func _ready():
	$TimeBar/GetTime.visible = false
	$TimeBar/LoseTime.visible = false
	time.one_shot = true
	GameManager.reset_conditions()
	GameManager.receiver_label = receiver
	for light in lights:
		_set_light_on(light, false)
	line_time_limit = time.wait_time
	_on_hackoins_changed(GameManager.hackoins, 0)
	GameManager.hackoins_changed.connect(_on_hackoins_changed)
	_generate_random_lines()
	inserter.gui_input.connect(_on_text_editor_gui_input)
	_load_current_line()
	_schedule_next_puzzle_window()

func _process(delta: float):
	if not phase_over:
		GameManager.game_time += delta
		_apply_time_acceleration(delta)
	_update_time_ui()
	_update_input_color()
#endregion

#region UI UPDATES
func _update_time_ui():
	game_time_text.text = _format_game_time(GameManager.game_time)
	if phase_over:
		return
	time_text.text = "%02d" % ceili(time.time_left)
	if time.time_left > 0:
		time_bar.value = time.time_left / line_time_limit * 100

func _format_game_time(total_seconds: float) -> String:
	var minutes := int(total_seconds / 60.0)
	var seconds := int(total_seconds) % 60
	var hundredths := int((total_seconds - int(total_seconds)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, hundredths]

# Blanco mientras se escribe bien, rojo si se desvía, verde si la línea está completa.
func _update_input_color():
	var typed = inserter.text
	var expected = receiver.text
	var color = Color.WHITE
	if typed == expected and typed != "":
		color = Color.GREEN
	elif not expected.begins_with(typed):
		color = Color.RED
	inserter.add_theme_color_override("font_color", color)
#endregion

#region PUZZLE WINDOW SPAWNING
func _is_phase_running() -> bool:
	return not phase_over and time.time_left > 0.0

func _schedule_next_puzzle_window():
	if not _is_phase_running():
		return
	var delay: float = randf_range(WINDOW_SPAWN_MIN, WINDOW_SPAWN_MAX)
	await get_tree().create_timer(delay).timeout
	_spawn_puzzle_window()

func _spawn_puzzle_window():
	if not _is_phase_running():
		return
	
	var window: PuzzleWindow = PUZZLE_WINDOW_SCENE.instantiate()
	add_child(window)
	_current_puzzle_window = window
	window.global_position = _random_window_position(window)
	
	var config: Dictionary = phase1_minigames.pick_random()
	var condition: PuzzleCondition = _pick_phase1_condition()
	
	window.solved.connect(_on_puzzle_window_solved)
	window.failed.connect(_on_puzzle_window_failed)
	window.closed.connect(_on_puzzle_window_closed)
	window.setup(config["scene"], condition, config.get("time_limit", 10.0))
	
	if randf() < MOVING_WINDOW_CHANCE:
		window.enable_bounce(_get_random_area_rect(), randf_range(MOVING_WINDOW_SPEED_MIN, MOVING_WINDOW_SPEED_MAX))
	
	camera.trigger_shake_x()

func _get_random_area_rect() -> Rect2:
	var shape := random_area.shape as RectangleShape2D
	if shape == null:
		return get_viewport().get_visible_rect()
	var size: Vector2 = shape.size * random_area.global_scale.abs()
	return Rect2(random_area.global_position - size / 2.0, size)

func _random_window_position(window: PuzzleWindow) -> Vector2:
	var area: Rect2 = _get_random_area_rect()
	var footprint: Rect2 = window.get_footprint()
	var free_space: Vector2 = (area.size - footprint.size).max(Vector2.ZERO)
	var top_left: Vector2 = area.position + Vector2(randf() * free_space.x, randf() * free_space.y)
	return top_left - footprint.position

# Descarta las condiciones que ya están activas (null = ventana sin condición).
func _pick_phase1_condition() -> PuzzleCondition:
	var available = phase1_conditions.filter(
		func(c): return c == null or not GameManager.is_condition_active(c.registry_key()))
	return available.pick_random()

func _close_active_puzzle_window():
	if _current_puzzle_window:
		_current_puzzle_window.queue_free()
		_current_puzzle_window = null
#endregion

#region PUZZLE WINDOW CALLBACKS
func _on_hackoins_changed(total: int, _delta: int):
	hackoins_text.text = "x" + str(total)

func _on_puzzle_window_solved(_window: PuzzleWindow, hackoin_reward: int):
	GameManager.add_hackoins(hackoin_reward)

func _on_puzzle_window_failed(_window: PuzzleWindow, time_penalty: float):
	_apply_time_penalty(time_penalty)
	animation_player.play("LoseTime")
	camera.trigger_shake_both_exes()

func _on_puzzle_window_closed(_window: PuzzleWindow):
	_current_puzzle_window = null
	inserter.grab_focus()
	_schedule_next_puzzle_window()
#endregion

#region LIGHTS
func _set_light_on(light: Panel, on: bool):
	var style = light.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		style.bg_color = Color(1, 1, 1, 1) if on else Color(0, 0, 0, 1)
#endregion

#region TEXT LINES MANAGEMENT
func _generate_random_lines():
	var shuffled = lines_pool.duplicate()
	shuffled.shuffle()
	lines_to_type = shuffled.slice(0, LINES_PER_PHASE)

func _load_current_line():
	if completed_lines < lines_to_type.size():
		receiver.text = lines_to_type[completed_lines]
	inserter.text = ""

func _set_combo(value: int):
	GameManager.lines_combo = value
	combo_text.text = "x" + str(value)
#endregion

#region INPUT HANDLING
func _on_text_editor_gui_input(event: InputEvent):
	if not (event is InputEventKey and event.pressed):
		return
	if GameManager.is_keyboard_locked():
		inserter.accept_event()
		return
	if event.is_echo():
		return
	
	if event.keycode == KEY_TAB:
		inserter.accept_event()
	elif event.keycode == KEY_ENTER:
		inserter.accept_event()
		_submit_line()

func _submit_line():
	if phase_over:
		return
	if inserter.text == receiver.text:
		_complete_line()
	else:
		_reject_line()

func _complete_line():
	completed_lines += 1
	_set_combo(GameManager.lines_combo + 1)
	time.start(time.time_left + success_time_get)
	animation_player.play("GetTime")
	
	if completed_lines - 1 < lights.size():
		_set_light_on(lights[completed_lines - 1], true)
	
	if completed_lines >= lines_to_type.size():
		inserter.text = ""
		_end_phase()
		$Victoria.show()
		animation_player.play("Victory")
		victory()
	else:
		_load_current_line()

func _reject_line():
	_apply_time_penalty(WRONG_LINE_PENALTY)
	_set_combo(0)
	camera.trigger_shake()
	animation_player.play("LoseTime")
#endregion

#region TIME MANAGEMENT
func _apply_time_acceleration(delta: float):
	if GameManager.time_speed > 1.0 and time.time_left > 0:
		_apply_time_penalty(delta * (GameManager.time_speed - 1.0))

func _apply_time_penalty(seconds: float):
	if phase_over:
		return
	var remaining = time.time_left - seconds
	if remaining <= 0.0:
		_on_time_timeout()
	else:
		time.start(remaining)

func _end_phase():
	phase_over = true
	time.stop()
	_close_active_puzzle_window()

func _on_time_timeout():
	if phase_over:
		return
	_end_phase()
	time_text.text = "00"
	time_bar.value = 0
	$LooseScreen.show()
#endregion

#region VICTORY / END
func victory():
	await get_tree().create_timer(3.0).timeout
	SceneManage.change_scene(self, "ThankYou")
#endregion
