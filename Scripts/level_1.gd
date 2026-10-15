extends Node

@export var success_time_get = 20.0

@onready var receiver = $Receiver/Label
@onready var inserter = $Inserter
@onready var time_bar = $TimeBar
@onready var time_text = $TimeBar/TimeText
@onready var time = $Time

@onready var light_1 = $Lights/Light1
@onready var light_2 = $Lights/Light2
@onready var light_3 = $Lights/Light3
@onready var light_4 = $Lights/Light4
@onready var light_5 = $Lights/Light5

@onready var combo_text = $"UI Coins-Combo/ComboText"
@onready var hackoins_text = $"UI Coins-Combo/HackoinsText"
@onready var game_time_text = $"UI Coins-Combo/GameTimeText"

@onready var animation_player = $AnimationPlayer
@onready var camera = $Camera2D

# Zona rectangular donde aparecen las ventanas-puzzle
@onready var random_area = $RandomArea/CollisionShape2D

# Escena base de la ventana-puzzle
const PUZZLE_WINDOW_SCENE = preload("res://Scenes/Puzzle-Windows/BaseVentanaPuzzle.tscn")

# Microjuegos
const KEEP_PRESSED_SCENE = preload("res://Scenes/Puzzle-Windows/KeepPressed.tscn")
const SIMON_SAYS_SCENE = preload("res://Scenes/Puzzle-Windows/SimonSays.tscn")
const THREE_TIMES_THREE_SCENE = preload("res://Scenes/Puzzle-Windows/ThreeTimesThree.tscn")
const CLOCK_ADJUST_SCENE = preload("res://Scenes/Puzzle-Windows/ClockAdjust.tscn")
const CABLES_CONNECT_SCENE = preload("res://Scenes/Puzzle-Windows/CablesConnect.tscn")

# Condicionadores
const ACCELERATOR_CONDITION: PuzzleCondition = preload("res://Scenes/Window Conditions/Accelerator.tres")
const KEYBOARD_LOCK_CONDITION: PuzzleCondition = preload("res://Scenes/Window Conditions/KeyboardLock.tres")

var phase1_minigames: Array[Dictionary] = [
	{ "scene": SIMON_SAYS_SCENE, "time_limit": 12.0 },
	{ "scene": KEEP_PRESSED_SCENE, "time_limit": 10.0 },
	{ "scene": THREE_TIMES_THREE_SCENE, "time_limit": 10.0 },
	{ "scene": CLOCK_ADJUST_SCENE, "time_limit": 10.0 },
	{ "scene": CABLES_CONNECT_SCENE, "time_limit": 10.0 }
]

var phase1_conditions = [null, KEYBOARD_LOCK_CONDITION, ACCELERATOR_CONDITION]

const WINDOW_SPAWN_MIN = 8.0
const WINDOW_SPAWN_MAX = 12.0

const MOVING_WINDOW_CHANCE = 0.35
const MOVING_WINDOW_SPEED_MIN = 70.0
const MOVING_WINDOW_SPEED_MAX = 110.0

var _current_puzzle_window: PuzzleWindow = null

var lights = []

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
	"#include “accountProtector.h” #define “virusDeleter.h”",
	"public: std::ostream& operator<<(std::ostream& in, std::ostream& out);",
	"Protector protector_shapes[]{prot1(12.5, 43.2), prot2(3.14, 2.71)}",
	"virtual void draw() const { std::cout << “Access denied” << std::endl; }",
	"private: double get_incognitus_location()",
	"bool informations = (hackers_identities < hackers_locations)",
	"auto info_a = expose(hacker_id, hacker_lctn, hacker_creditcard)"
]

var lines_to_type = []

var current_line_index = 0
var completed_lines = 0

var text_completed = false

var line_time_limit: float

func _ready():
	$TimeBar/GetTime.visible = false
	$TimeBar/LoseTime.visible = false
	randomize()
	time.one_shot = true
	GameManager.reset_conditions()
	GameManager.receiver_label = receiver
	lights = [light_1, light_2, light_3, light_4, light_5]
	for light in lights:
		_set_light_on(light, false)
	line_time_limit = time.wait_time
	_on_hackoins_changed(GameManager.hackoins, 0)
	GameManager.hackoins_changed.connect(_on_hackoins_changed)
	_generate_random_lines()
	inserter.gui_input.connect(_on_text_editor_gui_input)
	_load_current_line()
	_schedule_next_puzzle_window()

func _process(delta: float) -> void:
	if text_completed == false:
		GameManager.game_time += delta
	
	if GameManager.time_speed > 1.0 and not text_completed and time.time_left > 0:
		var extra_time: float = delta * (GameManager.time_speed - 1.0)
		_apply_time_penalty(extra_time)
	
	var minutes = float(GameManager.game_time) / 60
	var seconds = int(GameManager.game_time) % 60
	var miliseconds = int((GameManager.game_time - int(GameManager.game_time)) * 100)
	
	game_time_text.text = "%02d:%02d.%02d" % [minutes, seconds, miliseconds]
	
	if not text_completed:
		time_text.text = "%02d" % int(ceil(time.time_left))
		if time.time_left > 0:
			time_bar.value = (time.time_left / line_time_limit) * 100
	
	var expected = receiver.text
	var current = inserter.text
	
	if current == "":
		inserter.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		return
	
	if current == expected:
		inserter.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
		return
	
	var has_error = false
	var min_length = min(current.length(), expected.length())
	
	for i in range(min_length):
		if current[i] != expected[i]:
			has_error = true
			break
	
	if current.length() > expected.length():
		has_error = true
	
	if has_error:
		inserter.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
	else:
		inserter.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

func _schedule_next_puzzle_window() -> void:
	if text_completed or time.time_left <= 0.0:
		return
	var delay: float = randf_range(WINDOW_SPAWN_MIN, WINDOW_SPAWN_MAX)
	await get_tree().create_timer(delay).timeout
	_spawn_puzzle_window()

func _spawn_puzzle_window() -> void:
	if text_completed or time.time_left <= 0.0:
		return
	
	var window: PuzzleWindow = PUZZLE_WINDOW_SCENE.instantiate()
	add_child(window)
	window.global_position = _random_window_position(window)
	
	var config: Dictionary = phase1_minigames.pick_random()
	var condition: PuzzleCondition = _pick_phase1_condition()
	
	window.solved.connect(_on_puzzle_window_solved)
	window.failed.connect(_on_puzzle_window_failed)
	window.closed.connect(_on_puzzle_window_closed)
	window.setup(config.get("scene"), condition, config.get("time_limit", 10.0))
	
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

func _pick_phase1_condition() -> PuzzleCondition:
	var candidates: Array[PuzzleCondition] = []
	for condition in phase1_conditions:
		if condition == null:
			candidates.append(condition)
			continue
		var key: String = String(condition.get_script().get_global_name())
		if not GameManager.is_condition_active(key):
			candidates.append(condition)
	return candidates.pick_random()

func _on_puzzle_window_solved(_window: PuzzleWindow, hackoin_reward: int) -> void:
	GameManager.add_hackoins(hackoin_reward)

func _close_active_puzzle_window() -> void:
	if _current_puzzle_window:
		_current_puzzle_window.queue_free()
		_current_puzzle_window = null

func _on_hackoins_changed(total: int, _delta: int) -> void:
	hackoins_text.text = "x" + str(total)

func _on_puzzle_window_failed(_window: PuzzleWindow, time_penalty: float) -> void:
	_apply_time_penalty(time_penalty)
	animation_player.play("LoseTime")
	camera.trigger_shake_both_exes()

func _on_puzzle_window_closed(_window: PuzzleWindow) -> void:
	_current_puzzle_window = null
	inserter.grab_focus()
	_schedule_next_puzzle_window()

func _set_light_on(light: Panel, on: bool) -> void:
	var style = light.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		style.bg_color = Color(1, 1, 1, 1) if on else Color(0, 0, 0, 1)

func _generate_random_lines() -> void:
	var pool_copy = lines_pool.duplicate()
	pool_copy.shuffle()
	var amount = min(5, pool_copy.size())
	lines_to_type = pool_copy.slice(0, amount)

func _load_current_line() -> void:
	if current_line_index < lines_to_type.size():
		receiver.text = lines_to_type[current_line_index]
	inserter.text = ""

func _on_text_editor_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and GameManager.is_key_blocked(event.keycode):
		inserter.accept_event()
		return
	
	if event is InputEventKey and event.pressed and not event.is_echo():
		# Bloquear Tab
		if event.keycode == KEY_TAB:
			inserter.accept_event()
			return
		
		# Manejar Enter
		if event.keycode == KEY_ENTER:
			inserter.accept_event()
			
			if text_completed:
				return
			
			var expected = receiver.text
			var current = inserter.text
			
			# Si la línea coincide
			if current == expected:
				completed_lines += 1
				current_line_index += 1
				GameManager.lines_combo += 1
				combo_text.text = "x" + str(GameManager.lines_combo)
				var new_time = time.time_left + success_time_get
				time.stop()
				time.start(new_time)
				animation_player.play("GetTime")
				
				# Encender el indicador correspondiente a esta línea completada
				if completed_lines - 1 < lights.size():
					_set_light_on(lights[completed_lines - 1], true)
				
				print("¡Línea %d/%d completada!" % [completed_lines, lines_to_type.size()])
				
				if completed_lines >= lines_to_type.size():
					# Todas las líneas completadas: el jugador gana
					inserter.text = ""
					_end_phase()
					print("¡Texto completado! Tiempo detenido.")
					$Victoria.show()
					animation_player.play("Victory")
					victory()
				else:
					# Cargar la siguiente línea
					_load_current_line()
			# Si la línea no coincide con el Recibidor
			else:
				_apply_time_penalty(5.0)
				GameManager.lines_combo = 0
				camera.trigger_shake()
				combo_text.text = "x" + str(GameManager.lines_combo)
				animation_player.play("LoseTime")

func _apply_time_penalty(seconds: float) -> void:
	if text_completed:
		return
	
	var remaining = time.time_left - seconds
	time.stop()
	
	if remaining <= 0.0:
		_on_time_timeout()
	else:
		time.start(remaining)

func _end_phase() -> void:
	text_completed = true
	time.stop()
	_close_active_puzzle_window()

func _on_time_timeout() -> void:
	if text_completed:
		return
	_end_phase()
	time_text.text = "00"
	time_bar.value = 0
	print("¡Tiempo agotado!")
	$LooseScreen.show()

func victory() -> void:
	await get_tree().create_timer(3.0).timeout
	SceneManage.change_scene(self, "ThankYou")
