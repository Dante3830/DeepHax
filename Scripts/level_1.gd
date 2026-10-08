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

# Zona rectangular donde pueden aparecer las ventanas-puzzle: el
# CollisionShape2D del RandomArea (tiene que ser un RectangleShape2D).
@onready var random_area_shape: CollisionShape2D = $RandomArea/CollisionShape2D

# Escena de la ventana-puzzle
const PUZZLE_WINDOW_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/BaseVentanaPuzzle.tscn")

# Microjuegos
const MANTENER_PULSADO_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/KeepPressed.tscn")
const SIMON_DICE_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/SimonSays.tscn")
const IGUALAR_CUADROS_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/ThreeTimesThree.tscn")
const AJUSTAR_RELOJ_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/ClockAdjust.tscn")
const CONEXION_CABLES_SCENE: PackedScene = preload("res://Scenes/Puzzle-Windows/CablesConnect.tscn")

# Condicionadores
const ACELERADOR_CONDITION: PuzzleCondition = preload("res://Scenes/Window Conditions/Accelerator.tres")
const BLOQUEO_TECLADO_CONDITION: PuzzleCondition = preload("res://Scenes/Window Conditions/KeyboardLock.tres")

# Pool de la Fase 1, según la tabla "Frecuencia de aparición de las
# ventanas-puzzle" del GDD: Simón Dice, Laberinto, Mantener pulsado,
var phase1_minigames: Array[Dictionary] = [
	{ "scene": SIMON_DICE_SCENE, "time_limit": 12.0 },
	{ "scene": MANTENER_PULSADO_SCENE, "time_limit": 10.0 },
	{ "scene": IGUALAR_CUADROS_SCENE, "time_limit": 10.0 },
	{ "scene": AJUSTAR_RELOJ_SCENE, "time_limit": 10.0 },
	{ "scene": CONEXION_CABLES_SCENE, "time_limit": 10.0 }
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

# Cuántos segundos se muestra la animación de victoria antes de pasar a
# la escena ThankYou (la transición en sí dura aparte, ver SceneManage).
const VICTORY_SHOW_TIME: float = 3.0

# Ventanas que se mueven: probabilidad de que una ventana nueva rebote por
# el RandomArea, y su velocidad en px/seg (lento pero molesto).
const MOVING_WINDOW_CHANCE: float = 0.35
const MOVING_WINDOW_SPEED_MIN: float = 70.0
const MOVING_WINDOW_SPEED_MAX: float = 110.0

# Temblor horizontal de la pantalla cuando aparece una ventana.
const SPAWN_SHAKE_STRENGTH: float = 14.0  # píxeles de desplazamiento máximo
const SPAWN_SHAKE_DURATION: float = 0.35  # segundos
const SPAWN_SHAKE_CYCLES: float = 4.0     # idas y vueltas completas
var _shake_tween: Tween = null
var _camera_base_x: float = 0.0

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
	_camera_base_x = camera.position.x
	# El Timer del reloj viene SIN One Shot en la escena: al llegar a 0 se
	# reiniciaba solo con el último tiempo sobrante (start(remaining) le
	# cambia el wait_time) y el reloj "se loopeaba" después de perder.
	time.one_shot = true
	# Red de seguridad: GameManager es un autoload y su estado sobrevive
	# a recargar la escena, así que arrancamos con las condiciones en cero.
	GameManager.reset_conditions()
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
	_schedule_next_puzzle_window()

# Espera un tiempo al azar (8-12s en Fase 1) y genera la siguiente
# ventana-puzzle, mientras la fase siga en curso.
func _schedule_next_puzzle_window() -> void:
	if text_completed or time.time_left <= 0.0:
		return
	var delay: float = randf_range(WINDOW_SPAWN_MIN, WINDOW_SPAWN_MAX)
	await get_tree().create_timer(delay).timeout
	_spawn_puzzle_window()

# Instancia una ventana-puzzle nueva en un lugar al azar dentro del
# RandomArea, con un microjuego y una condición al azar del pool de la Fase 1.
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

	# Algunas ventanas rebotan por el RandomArea en vez de quedarse quietas.
	if randf() < MOVING_WINDOW_CHANCE:
		window.enable_bounce(_get_random_area_rect(), randf_range(MOVING_WINDOW_SPEED_MIN, MOVING_WINDOW_SPEED_MAX))

	_shake_screen_horizontal()
	_current_puzzle_window = window

# Sacude la pantalla de izquierda a derecha, con más fuerza al principio y
# amortiguándose hasta quedar quieta. Mueve camera.position.x (y no offset)
# para no pisarse con trigger_shake(), que suele usar offset.
func _shake_screen_horizontal() -> void:
	if _shake_tween:
		_shake_tween.kill()
	camera.position.x = _camera_base_x
	_shake_tween = create_tween()
	_shake_tween.tween_method(_set_horizontal_shake, 0.0, 1.0, SPAWN_SHAKE_DURATION)

func _set_horizontal_shake(progress: float) -> void:
	var wave := sin(progress * TAU * SPAWN_SHAKE_CYCLES)
	camera.position.x = _camera_base_x + wave * SPAWN_SHAKE_STRENGTH * (1.0 - progress)

# Rectángulo global del RandomArea. Se lee del CollisionShape2D cada vez,
# así que si lo movés o lo escalás en el editor no hay que tocar código.
# (Solo soporta RectangleShape2D, sin rotación.)
func _get_random_area_rect() -> Rect2:
	var shape := random_area_shape.shape as RectangleShape2D
	if shape == null:
		push_warning("El CollisionShape2D del RandomArea tiene que ser un RectangleShape2D.")
		return get_viewport().get_visible_rect()
	var size: Vector2 = shape.size * random_area_shape.global_scale.abs()
	return Rect2(random_area_shape.global_position - size / 2.0, size)

# Posición al azar para que la ventana ENTERA (no solo su esquina) quede
# dentro del RandomArea. Si el área es más chica que la ventana, la pega
# a la esquina superior izquierda del área.
func _random_window_position(window: PuzzleWindow) -> Vector2:
	var area: Rect2 = _get_random_area_rect()
	var footprint: Rect2 = window.get_footprint()
	var free_space: Vector2 = (area.size - footprint.size).max(Vector2.ZERO)
	var top_left: Vector2 = area.position + Vector2(randf() * free_space.x, randf() * free_space.y)
	return top_left - footprint.position

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

func _on_hackoins_changed(total: int, _delta: int) -> void:
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
	# Si el microjuego usó Buttons, le robaron el foco al TextEdit.
	text_editor.grab_focus()
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
	# Condición "Bloqueo de teclado": va ANTES del filtro de eco; si no,
	# dejando apretada la tecla bloqueada se escribe igual.
	if event is InputEventKey and event.pressed and GameManager.is_key_blocked(event.keycode):
		text_editor.accept_event()
		return

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
					_end_phase()
					print("¡Texto completado! Tiempo detenido.")
					$Victoria.show()
					animation_player.play("Victory")
					victory()
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
	if text_completed == false:
		GameManager.game_time += delta
	# Condición "Acelerador": el Timer de Godot no tiene una velocidad
	# configurable, así que mientras haya algún multiplicador activo le
	# restamos el tiempo "extra" (más allá del segundo a segundo normal)
	# usando la misma función que ya usamos para las penalizaciones.
	if GameManager.time_speed_multiplier > 1.0 and not text_completed and time.time_left > 0:
		var extra_time: float = delta * (GameManager.time_speed_multiplier - 1.0)
		_apply_time_penalty(extra_time)
	
	var minutes := int(GameManager.game_time) / 60
	var seconds := int(GameManager.game_time) % 60
	var miliseconds := int((GameManager.game_time - int(GameManager.game_time)) * 100)
	
	game_time_text.text = "%02d:%02d.%02d" % [minutes, seconds, miliseconds]
	
	# Mientras se juega, el texto sigue al Timer. Al terminar la fase deja de
	# actualizarse: si ganó queda congelado con el tiempo que sobraba, y si
	# perdió _on_time_timeout() ya lo dejó en "00".
	if not text_completed:
		time_text.text = "%02d" % int(ceil(time.time_left))
		if time.time_left > 0:
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

# Cierra la fase, ganando o perdiendo, y corta todo lo que seguía corriendo.
# Tener UN solo lugar evita que un camino de salida se olvide de algo (al
# perder se dejaba vivo el Timer, y por eso el reloj seguía y podían volver
# a aparecer ventanas).
func _end_phase() -> void:
	text_completed = true  # frena game_time, el spawn de ventanas y los Enter
	time.stop()            # el reloj no puede reiniciarse ni volver a disparar
	_close_active_puzzle_window()

func _on_time_timeout() -> void:
	# Puede llegar dos veces (señal del Timer + una penalización que agota
	# el tiempo): la segunda no tiene que hacer nada.
	if text_completed:
		return
	_end_phase()
	# El reloj vacío siempre se lee "00" (y la barra, en cero).
	time_text.text = "00"
	time_bar.value = 0
	print("¡Tiempo agotado!")
	$LooseScreen.show()

func victory() -> void:
	await get_tree().create_timer(VICTORY_SHOW_TIME).timeout
	SceneManage.change_scene(self, "ThankYou")
