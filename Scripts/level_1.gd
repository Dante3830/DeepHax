extends Node

@onready var receiving_code = $ReceivingCode/Label
@onready var text_editor = $TextEditor
@onready var time_bar = $TimeBar
@onready var time = $Time

var completed_lines = 0

var text_completed = false

func _ready():
	# Conectar la señal gui_input del TextEdit para capturar Enter
	text_editor.gui_input.connect(_on_text_editor_gui_input)

func _on_text_editor_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# Bloquear Tab
		if event.keycode == KEY_TAB:
			text_editor.accept_event()
			return
		
		# Manejar Enter
		if event.keycode == KEY_ENTER:
			text_editor.accept_event()
			
			var expected = receiving_code.text
			var current = text_editor.text
			
			if current == expected and not text_completed:
				text_editor.text = ""
				time.stop()
				text_completed = true
				print("¡Texto completado! Tiempo detenido.")

func _process(delta: float) -> void:
	if not text_completed and time.time_left > 0:
		time_bar.value = (time.time_left / time.wait_time) * 100
	
	var expected = receiving_code.text
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
