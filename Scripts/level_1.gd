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
@onready var hackoins_text = $"UI Coins-Combo/HackoinsText"

@onready var animation_player = $AnimationPlayer
@onready var camera = $Camera2D

# Única ventana-puzzle de pruebas. PuzzleWindow se destruye sola
# (queue_free) apenas se resuelve o falla, así que para probar varios
# microjuegos uno detrás de otro vamos a ir generando una ventana nueva
# en el mismo lugar cada vez (ver _test_transform más abajo).
@onready var test_window: PuzzleWindow = $TestPuzzleWindow

# Escena de la ventana-puzzle en sí, para poder instanciar una nueva
# copia cada vez que la anterior se cierre sola.
const PUZZLE_WINDOW_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/BaseVentanaPuzzle.tscn")

# Ajustá esta ruta a donde hayas guardado la escena de Mantener Pulsado.
const MANTENER_PULSADO_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/KeepPressed.tscn")

# Ajustá esta ruta a donde hayas guardado la escena de Simón Dice.
const SIMON_DICE_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/SimonSays.tscn")

# Ajustá esta ruta a donde hayas guardado la escena de Igualar cuadros 3x3.
const IGUALAR_CUADROS_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/ThreeTimesThree.tscn")

# Ajustá esta ruta a donde hayas guardado la escena de Ajustar reloj.
const AJUSTAR_RELOJ_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/ClockAdjust.tscn")

# Ajustá esta ruta a donde hayas guardado la escena de Conexión de cables.
const CONEXION_CABLES_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/CablesConnect.tscn")

# Microjuegos a probar, uno por uno, en el orden de esta lista. Agregá
# acá los que quieras ir sumando (y su tiempo límite correspondiente).
var test_minigames: Array[Dictionary] = [
	{ "scene": MANTENER_PULSADO_SCENE, "time_limit": 10.0 },
	{ "scene": SIMON_DICE_SCENE, "time_limit": 12.0 },
	{ "scene": IGUALAR_CUADROS_SCENE, "time_limit": 15.0 },
	{ "scene": AJUSTAR_RELOJ_SCENE, "time_limit": 30.0 },
	{ "scene": CONEXION_CABLES_SCENE, "time_limit": 20.0 },
]
var _test_index: int = 0

# Anclas/offsets de la ventana puesta a mano en el editor, para clonar
# su posición cada vez que generemos una ventana nueva.
var _test_transform: Array = []

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
	# Condición "Desorden visual": le da a GameManager la referencia al
	# Label para poder aplicarle el shader de glitch mientras esté activa.
	GameManager.receiver_label = receiver
	lights = [light_1, light_2, light_3, light_4, light_5]
	for light in lights:
		_set_light_on(light, false)
	line_time_limit = time.wait_time
	_on_hackoins_changed(GameManager.hackoins, 0)
	GameManager.hackoins_changed.connect(_on_hackoins_changed)
	_generate_random_lines()
	# Conectar la señal gui_input del TextEdit para capturar Enter
	text_editor.gui_input.connect(_on_text_editor_gui_input)
	_load_current_line()

	# Guardamos la posición/tamaño de la ventana puesta en el editor
	# para poder clonarla cada vez que probemos el siguiente microjuego.
	_test_transform = [
		test_window.anchor_left, test_window.anchor_top,
		test_window.anchor_right, test_window.anchor_bottom,
		test_window.offset_left, test_window.offset_top,
		test_window.offset_right, test_window.offset_bottom,
	]
	_run_test_window(test_window)

# Arranca en la ventana dada el microjuego que le toca según _test_index.
func _run_test_window(window: PuzzleWindow) -> void:
	if _test_index >= test_minigames.size():
		print("Ya probaste todos los microjuegos de la lista.")
		return
	var config: Dictionary = test_minigames[_test_index]
	window.solved.connect(_on_test_window_solved)
	window.failed.connect(_on_test_window_failed)
	window.closed.connect(_on_test_window_closed)
	window.setup(config.get("scene"), config.get("condition"), config.get("time_limit", 10.0))

# La ventana anterior ya se destruyó sola (PuzzleWindow._close() hace
# queue_free), así que generamos una nueva en el mismo lugar para
# probar el siguiente microjuego de la lista.
func _on_test_window_closed(_window: PuzzleWindow) -> void:
	_test_index += 1
	if _test_index >= test_minigames.size():
		print("Ya probaste todos los microjuegos de la lista.")
		return

	var next_window: PuzzleWindow = PUZZLE_WINDOW_SCENE.instantiate()
	add_child(next_window)
	next_window.anchor_left = _test_transform[0]
	next_window.anchor_top = _test_transform[1]
	next_window.anchor_right = _test_transform[2]
	next_window.anchor_bottom = _test_transform[3]
	next_window.offset_left = _test_transform[4]
	next_window.offset_top = _test_transform[5]
	next_window.offset_right = _test_transform[6]
	next_window.offset_bottom = _test_transform[7]
	_run_test_window(next_window)

func _on_test_window_solved(_window: PuzzleWindow, hackoin_reward: int) -> void:
	print("Puzzle resuelto. Hackoins ganados: ", hackoin_reward)
	GameManager.add_hackoins(hackoin_reward)

func _on_hackoins_changed(total: int, delta: int) -> void:
	hackoins_text.text = "x" + str(total)
	#if delta > 0:
		#_show_hackoin_popup(delta)

# Cartelito "+N" que cae debajo del contador y se desvanece.
#func _show_hackoin_popup(amount: int) -> void:
	#var popup := Label.new()
	#popup.text = "+" + str(amount)
	#popup.add_theme_font_override("font", hackoins_text.get_theme_font("font"))
	#popup.add_theme_font_size_override("font_size", 44)
	#popup.add_theme_color_override("font_color", Color(1, 0.9, 0))
	#popup.position = hackoins_text.position + Vector2(0, 85)
	#hackoins_text.get_parent().add_child(popup)
#
	#var tween := popup.create_tween().set_parallel(true)
	#tween.tween_property(popup, "position:y", popup.position.y + 40, 0.8)
	#tween.tween_property(popup, "modulate:a", 0.0, 0.8)
	#tween.chain().tween_callback(popup.queue_free)

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
		# Condición "Bloqueo de teclado": si hay una tecla inhabilitada
		# por alguna ventana-puzzle abierta, no dejarla pasar.
		if GameManager.is_key_blocked(event.keycode):
			text_editor.accept_event()
			return

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
	# Condición "Acelerador": el Timer de Godot no tiene una velocidad
	# configurable, así que mientras haya algún multiplicador activo le
	# restamos el tiempo "extra" (más allá del segundo a segundo normal)
	# usando la misma función que ya usamos para las penalizaciones.
	if GameManager.time_speed_multiplier > 1.0 and not text_completed and time.time_left > 0:
		var extra_time: float = _delta * (GameManager.time_speed_multiplier - 1.0)
		_apply_time_penalty(extra_time)

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
	$LooseScreen.show()
