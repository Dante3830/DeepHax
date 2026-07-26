extends Node

@onready var receiver = $Receiver/Label
@onready var text_editor = $TextEditor
@onready var time_bar = $TimeBar
@onready var time = $Time

@onready var light_1 = $Lights/Light1
@onready var light_2 = $Lights/Light2
@onready var light_3 = $Lights/Light3
@onready var light_4 = $Lights/Light4
@onready var light_5 = $Lights/Light5

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

func _ready():
	randomize()
	lights = [light_1, light_2, light_3, light_4, light_5]
	for light in lights:
		_set_light_on(light, false)
	_generate_random_lines()
	# Conectar la señal gui_input del TextEdit para capturar Enter
	text_editor.gui_input.connect(_on_text_editor_gui_input)
	_load_current_line()

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
	if event is InputEventKey and event.pressed:
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
			
			if current == expected:
				completed_lines += 1
				current_line_index += 1
				
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
				else:
					# Quedan líneas: cargar la siguiente y reiniciar el temporizador
					_load_current_line()
					time.stop()
					time.start()

func _process(_delta: float) -> void:
	if not text_completed and time.time_left > 0:
		time_bar.value = (time.time_left / time.wait_time) * 100
	
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
