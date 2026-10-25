class_name Difference
extends PuzzleMinigame

const CODE_LENGTH = 7
const CODE_CHARS = "ABEFJKLPRSTUZ23456789"
const MAX_TEXT_WIDTH = 187.0

const LOOKALIKES = { "7": "T", "T": "7", "5": "S", "S": "5", "8": "B", "B": "8",
	"2": "Z", "Z": "2", "6": "G", "U": "V", "E": "F", "F": "E",
	"P": "R", "R": "P", "4":"A" }

@onready var originalLabel: Label = $Label2
@onready var modifiedLabel: Label = $Label3

var differentIndex = -1

func _ready():
	generate_codes()
	modifiedLabel.mouse_filter = Control.MOUSE_FILTER_STOP
	modifiedLabel.gui_input.connect(on_modified_gui_input)

func generate_codes():
	var original = ""
	var modified = ""
	for _attempt in 50:
		original = ""
		for _i in CODE_LENGTH:
			original += CODE_CHARS[randi() % CODE_CHARS.length()]
		differentIndex = randi() % CODE_LENGTH
		var oldChar: String = original[differentIndex]
		var newChar: String = LOOKALIKES.get(oldChar, "")
		while newChar == "" or newChar == oldChar:
			newChar = CODE_CHARS[randi() % CODE_CHARS.length()]
		modified = original.substr(0, differentIndex) + newChar + original.substr(differentIndex + 1)
		if get_text_width(original) <= MAX_TEXT_WIDTH and get_text_width(modified) <= MAX_TEXT_WIDTH:
			break
	originalLabel.text = original
	modifiedLabel.text = modified

func get_text_width(text: String) -> float:
	var font: Font = modifiedLabel.get_theme_font("font")
	var fontSize: int = modifiedLabel.get_theme_font_size("font_size")
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize).x

func on_modified_gui_input(event: InputEvent):
	if isFinished:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var clickedIndex = get_char_index_at(modifiedLabel, event.position.x)
	if clickedIndex == -1:
		return # clic fuera del texto: se ignora
	notify_interaction()
	var success = clickedIndex == differentIndex
	modifiedLabel.add_theme_color_override("font_color", Color.GREEN if success else Color.RED)
	finish(success)

# Devuelve qué carácter del Label está bajo la posición x (local al Label), o -1 si no hay ninguno.
func get_char_index_at(label: Label, x: float) -> int:
	var font: Font = label.get_theme_font("font")
	var fontSize: int = label.get_theme_font_size("font_size")
	for i in label.text.length():
		var rightEdge = font.get_string_size(label.text.substr(0, i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize).x
		if x < rightEdge:
			return i
	return -1
