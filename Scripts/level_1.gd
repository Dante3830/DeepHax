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
@onready var game_time_text = $"UI Coins-Combo/GameTimeText"

@onready var animation_player = $AnimationPlayer
@onready var camera = $Camera2D

# Ventana-puzzle colocada a mano en el editor, usada solo como referencia
# de posición: se clona su transform (ver _window_spawn_transform) para
# cada ventana nueva que genere el spawner, y se destruye apenas arranca
# el nivel (no se usa directamente como ventana real).
@onready var window_spawn_point: PuzzleWindow = $TestPuzzleWindow

# Escena de la ventana-puzzle en sí, para poder instanciar una nueva
# copia cada vez que la anterior se cierre sola.
const PUZZLE_WINDOW_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/BaseVentanaPuzzle.tscn")

# Ajustá esta ruta a donde hayas guardado la escena de Mantener Pulsado.
const MANTENER_PULSADO_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/KeepPressed.tscn")

# Ajustá esta ruta a donde hayas guardado la escena de Simón Dice.
const SIMON_DICE_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/SimonSays.tscn")

# Estas 3 son de Fase 2 y 3 según el GDD, todavía no entran en el pool de
# la Fase 1 (phase1_minigames, más abajo). Las dejo precargadas para
# cuando armemos esas fases.
const IGUALAR_CUADROS_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/ThreeTimesThree.tscn")
const AJUSTAR_RELOJ_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/ClockAdjust.tscn")
const CONEXION_CABLES_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/CablesConnect.tscn")

# Creá estos dos recursos en el editor si todavía no existen (click derecho
# en la carpeta → Nuevo recurso → Acelerador / BloqueoDeTeclado) y ajustá
# la ruta si los guardaste en otro lado.
const ACELERADOR_CONDITION: PuzzleCondition = preload("res://Resources/Conditions/Acelerador.tres")
const BLOQUEO_TECLADO_CONDITION: PuzzleCondition = preload("res://Resources/Conditions/BloqueoDeTeclado.tres")

# Pool de la Fase 1, según la tabla "Frecuencia de aparición de las
# ventanas-puzzle" del GDD: Simón Dice, Laberinto, Mantener pulsado,
# Pulsar repetidamente. Todavía no armamos Laberinto ni Pulsar
# repetidamente - sumalos acá apenas los programemos.
var phase1_minigames: Array[Dictionary] = [
	{ "scene": SIMON_DICE_SCENE, "time_limit": 12.0 },
	{ "scene": MANTENER_PULSADO_SCENE, "time_limit": 10.0 },
]

# Condiciones de la Fase 1 (según la misma tabla): Bloqueo de teclado y
# Acelerador. null = sin condición, para que no todas las ventanas tengan
# una.
var phase1_conditions: Array[PuzzleCondition] = [null, BLOQUEO_TECLADO_CONDITION, ACELERADOR_CONDITION]

# Frecuencia de aparición de la Fase 1 según el GDD: 8-12 segundos. Por
# ahora es el tiempo de espera desde que se cierra una ventana hasta que
# aparece la siguiente, ya que solo dejamos una ventana abierta a la vez.
const WINDOW_SPAWN_MIN: float = 8.0
const WINDOW_SPAWN_MAX: float = 12.0

# Anclas/offsets de la ventana puesta a mano en el editor, para clonar
# su posición cada vez que el spawner genere una ventana nueva.
var _window_spawn_transform: Array = []

# Ventana-puzzle actualmente abierta, o null si no hay ninguna.
var _current_puzzle_window: PuzzleWindow = null

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
	
	# Guardamos la posición/tamaño de la ventana puesta en el editor para
	# poder clonarla cada vez que el spawner genere una ventana nueva, y
	# destruimos la de referencia (no es una ventana real).
	_window_spawn_transform = [
		window_spawn_point.anchor_left, window_spawn_point.anchor_top,
		window_spawn_point.anchor_right, window_spawn_point.anchor_bottom,
		window_spawn_point.offset_left, window_spawn_point.offset_top,
		window_spawn_point.offset_right, window_spawn_point.offset_bottom,
	]
	window_spawn_point.queue_free()
	_schedule_next_puzzle_window()

# Espera un tiempo al azar (8-12s en Fase 1) y genera la siguiente
# ventana-puzzle, mientras la fase siga en curso.
func _schedule_next_puzzle_window() -> void:
	if text_completed or time.time_left <= 0.0:
		return
	var delay: float = randf_range(WINDOW_SPAWN_MIN, WINDOW_SPAWN_MAX)
	await get_tree().create_timer(delay).timeout
	_spawn_puzzle_window()

# Instancia una ventana-puzzle nueva en la posición de referencia, con un
# microjuego y una condición al azar del pool de la Fase 1.
func _spawn_puzzle_window() -> void:
	if text_completed or time.time_left <= 0.0:
		return

	var window: PuzzleWindow = PUZZLE_WINDOW_SCENE.instantiate()
	add_child(window)
	window.anchor_left = _window_spawn_transform[0]
	window.anchor_top = _window_spawn_transform[1]
	window.anchor_right = _window_spawn_transform[2]
	window.anchor_bottom = _window_spawn_transform[3]
	window.offset_left = _window_spawn_transform[4]
	window.offset_top = _window_spawn_transform[5]
	window.offset_right = _window_spawn_transform[6]
	window.offset_bottom = _window_spawn_transform[7]

	var config: Dictionary = phase1_minigames.pick_random()
	var condition: PuzzleCondition = _pick_phase1_condition()

	window.solved.connect(_on_puzzle_window_solved)
	window.failed.connect(_on_puzzle_window_failed)
	window.closed.connect(_on_puzzle_window_closed)
	window.setup(config.get("scene"), condition, config.get("time_limit", 10.0))

	_current_puzzle_window = window

# Elige una condición del pool de la Fase 1 que no esté ya activa en otra
# ventana abierta (ver GameManager.is_condition_active). null (sin
# condición) siempre es una opción válida.
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

# Cierra la ventana-puzzle abierta sin pasar por sus señales solved/failed
# (se usa cuando termina la fase o el tiempo, no cuando el jugador la
# resuelve o falla de verdad).
func _close_active_puzzle_window() -> void:
	if _current_puzzle_window:
		_current_puzzle_window.queue_free()
		_current_puzzle_window = null

func _on_hackoins_changed(total: int, delta: int) -> void:
	hackoins_text.text = "x" + str(total)
	#if delta > 0:
		#_show_hackoin_popup(delta)

func _on_puzzle_window_failed(_window: PuzzleWindow, time_penalty: float) -> void:
	_apply_time_penalty(time_penalty)
	animation_player.play("MinusFive")
	camera.trigger_shake()

# La ventana se cerró sola (resuelta o fallada): programamos la próxima.
func _on_puzzle_window_closed(_window: PuzzleWindow) -> void:
	_current_puzzle_window = null
	_schedule_next_puzzle_window()

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
					_close_active_puzzle_window()
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

func _process(delta: float) -> void:
	# Condición "Acelerador": el Timer de Godot no tiene una velocidad
	# configurable, así que mientras haya algún multiplicador activo le
	# restamos el tiempo "extra" (más allá del segundo a segundo normal)
	# usando la misma función que ya usamos para las penalizaciones.
	if GameManager.time_speed_multiplier > 1.0 and not text_completed and time.time_left > 0:
		var extra_time: float = delta * (GameManager.time_speed_multiplier - 1.0)
		_apply_time_penalty(extra_time)
	
	GameManager.game_time += delta
	
	var minutes := int(GameManager.game_time) / 60
	var seconds := int(GameManager.game_time) % 60
	var miliseconds := int((GameManager.game_time - int(GameManager.game_time)) * 100)
	
	game_time_text.text = "%02d:%02d.%02d" % [minutes, seconds, miliseconds]
	
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
	_close_active_puzzle_window()
	print("¡Tiempo agotado!")
	$LooseScreen.show()
