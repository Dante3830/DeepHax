extends Node

@onready var receiver = $Receiver/Label
@onready var text_editor = $TextEditor
@onready var time_bar = $TimeBar
@onready var time_text = $TimeBar/TimeText
@onready var time = $Time

@onready var light_1 = $Lights/Light1
@onready var light_2 = $Lights/Light2
@onready var light_3 = $Lights/Light3
@onready var light_4 = $Lights/Light4
@onready var light_5 = $Lights/Light5

@onready var combo_text = $"UI Coins-Combo/ComboText"

@onready var animation_player = $AnimationPlayer
@onready var camera = $Camera2D

# Ventana-puzzle dedicada a pruebas (nodo separado del que vayas a usar
# para el Simón Dice real más adelante).
@onready var test_window: PuzzleWindow = $TestPuzzleWindow

# Segundo nodo de prueba, para no pisar el de Mantener Pulsado.
@onready var test_window_2: PuzzleWindow = $TestPuzzleWindow2

# Ajustá esta ruta a donde hayas guardado la escena de Mantener Pulsado.
const MANTENER_PULSADO_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/KeepPressed.tscn")

# Ajustá esta ruta a donde hayas guardado la escena de Simón Dice.
const SIMON_DICE_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/SimonSays.tscn")

# Array con las 5 luces en orden, para acceder a ellas por índice
var lights = []

# Pool de líneas en C++ disponibles. Podés agregar tantas como quieras:
# en cada partida se eligen 5 al azar, sin repetir, en orden aleatorio.
var lines_pool = [
	"int access_level = 0;",
	"bool breach = firewall.attempt();",
	"if (breach == true) {",
	"decrypt(target_node);",
	"char* payload = exploit_buffer;",
	"system.upload(payload, server);",
	"std::cout << access granted;",
	"void exit_terminal() {",
	"return 0;",
	"for (int i = 0; i < nodes; i++) {",
	"nodes[i].bypass();",
	"const int MAX_RETRIES = 3;",
	"while (!connected) { retry(); }"
]

# Líneas que se usarán en esta partida (5, elegidas al azar del pool, sin repetir)
var lines_to_type = []

var current_line_index = 0
var completed_lines = 0

var text_completed = false

var line_time_limit: float = 0.0

func _ready():
	$TimeBar/MinusFive.visible = false
	randomize()
	lights = [light_1, light_2, light_3, light_4, light_5]
	for light in lights:
		_set_light_on(light, false)
	line_time_limit = time.wait_time
	combo_text.text = "x" + str(GameManager.lines_combo)
	_generate_random_lines()
	# Conectar la señal gui_input del TextEdit para capturar Enter
	text_editor.gui_input.connect(_on_text_editor_gui_input)
	_load_current_line()

	# Prueba de Mantener Pulsado en la ventana ya colocada en la escena
	test_window.setup(MANTENER_PULSADO_SCENE)
	test_window.solved.connect(_on_test_window_solved)
	test_window.failed.connect(_on_test_window_failed)

	# Prueba de Simón Dice en el segundo nodo de prueba
	test_window_2.setup(SIMON_DICE_SCENE, null, 12.0)
	test_window_2.solved.connect(_on_test_window_solved)
	test_window_2.failed.connect(_on_test_window_failed)

func _on_test_window_solved(_window: PuzzleWindow, hackoin_reward: int) -> void:
	print("Puzzle resuelto. Hackoins ganados: ", hackoin_reward)
	# Acá después vas a llamar a tu sistema real de Hackoins.

func _on_test_window_failed(_window: PuzzleWindow, time_penalty: float) -> void:
	print("Puzzle fallado. Penalización: ", time_penalty)
	_apply_time_penalty(time_penalty)
	animation_player.play("MinusFive")
	camera.trigger_shake()

func _set_light_on(light: Panel, on: bool) -> void:
	# Cambia solo el bg_color del StyleBoxFlat del panel, manteniendo el borde intacto
	var style = light.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		style.bg_color = Color(1, 1, 1, 1) if on else Color(0, 0, 0, 1)

func _generate_random_lines() -> void:
	# Copia el pool, lo mezcla y toma las primeras 5 (o menos, si el pool es más chico)
	var pool_copy = lines_pool.duplicate()
	pool_copy.shuffle()
	var amount = min(5, pool_copy.size())
	lines_to_type = pool_copy.slice(0, amount)

func _load_current_line() -> void:
	# Muestra la línea actual que el jugador debe escribir
	if current_line_index < lines_to_type.size():
		receiver.text = lines_to_type[current_line_index]
	text_editor.text = ""

func _on_text_editor_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		# Bloquear Tab
		if event.keycode == KEY_TAB:
			text_editor.accept_event()
			return
		
		# Manejar Enter
		if event.keycode == KEY_ENTER:
			text_editor.accept_event()
			
			if text_completed:
				return
			
			var expected = receiver.text
			var current = text_editor.text
			
			# Si la línea coincide con el Receiber
			if current == expected:
				completed_lines += 1
				current_line_index += 1
				GameManager.lines_combo += 1
				combo_text.text = "x" + str(GameManager.lines_combo)
				
				# Encender el indicador correspondiente a esta línea completada
				if completed_lines - 1 < lights.size():
					_set_light_on(lights[completed_lines - 1], true)
				
				print("¡Línea %d/%d completada!" % [completed_lines, lines_to_type.size()])
				
				if completed_lines >= lines_to_type.size():
					# Todas las líneas completadas: el jugador gana
					text_editor.text = ""
					time.stop()
					text_completed = true
					print("¡Texto completado! Tiempo detenido.")
					$Victoria.show()
					animation_player.play("Victory")
				else:
					# Quedan líneas: cargar la siguiente y reiniciar el temporizador
					_load_current_line()
					time.stop()
					time.start(line_time_limit)
			# Si la línea NO coincide con el Receiber
			else:
				print("Línea incorrecta. Penalización: -5 segundos.")
				_apply_time_penalty(5.0)
				GameManager.lines_combo = 0
				camera.trigger_shake()
				combo_text.text = "x" + str(GameManager.lines_combo)
				animation_player.play("MinusFive")

func _apply_time_penalty(seconds: float) -> void:
	# Timer.time_left es de solo lectura en Godot, así que para "quitarle" tiempo
	# hay que detener el Timer y volver a arrancarlo con el tiempo restante ya reducido.
	if text_completed:
		return
	
	var remaining = time.time_left - seconds
	time.stop()
	
	if remaining <= 0.0:
		# La penalización agota el tiempo restante: game over inmediato
		_on_time_timeout()
	else:
		time.start(remaining)

func _process(_delta: float) -> void:
	var seconds_left = int(ceil(time.time_left))
	time_text.text = "%02d" % seconds_left
	
	if not text_completed and time.time_left > 0:
		time_bar.value = (time.time_left / line_time_limit) * 100
	
	var expected = receiver.text
	var current = text_editor.text
	
	if current == "":
		text_editor.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		return
	
	if current == expected:
		text_editor.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
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
		text_editor.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
	else:
		text_editor.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

func _on_time_timeout() -> void:
	print("¡Tiempo agotado!")
	$"Game Over".show()
