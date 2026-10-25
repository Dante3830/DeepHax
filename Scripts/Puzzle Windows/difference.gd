class_name Difference
extends PuzzleMinigame

const CODE_CHARACTERS = "ABEFGIJKLMNOPRSTUZ1234567890"
const MAX_TEXT_WIDTH = 187.0

const DOPPELGANGERS = { "7":"T", "T":"7", "5":"S", "S":"5", "8":"B", "B":"8",
					"2":"Z", "Z":"2", "6":"G", "U":"V", "E":"F", "F":"E",
					"P":"R", "R":"P", "4":"A", "A":"4", "1":"I", "I":"1",
					"N":"M", "M":"N", "0":"O", "O":"0" }

@onready var originalSerNum = $originalSN
@onready var modifiedSerNum = $modifiedSN

var differentIndex = -1
var serNumberLength = 7

func _ready():
	generate_codes()
	modifiedSerNum.mouse_filter = Control.MOUSE_FILTER_STOP

func generate_codes():
	var original = ""
	var modified = ""
	for i in 50:
		original = ""
		for character in serNumberLength:
			original += CODE_CHARACTERS[randi() % CODE_CHARACTERS.length()]
		differentIndex = randi() % serNumberLength
		var oldChar: String = original[differentIndex]
		var newChar: String = DOPPELGANGERS.get(oldChar, "")
		while newChar == "" or newChar == oldChar:
			newChar = CODE_CHARACTERS[randi() % CODE_CHARACTERS.length()]
		modified = original.substr(0, differentIndex) + newChar + original.substr(differentIndex + 1)
		if get_text_width(original) <= MAX_TEXT_WIDTH and get_text_width(modified) <= MAX_TEXT_WIDTH:
			break
	originalSerNum.text = original
	modifiedSerNum.text = modified

func get_text_width(text: String) -> float:
	var font = modifiedSerNum.get_theme_font("font")
	var fontSize = modifiedSerNum.get_theme_font_size("font_size")
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize).x

func get_char_index_at(label: Label, x: float) -> int:
	var font = label.get_theme_font("font")
	var fontSize = label.get_theme_font_size("font_size")
	for i in label.text.length():
		var rightEdge = font.get_string_size(label.text.substr(0, i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize).x
		if x < rightEdge:
			return i
	return -1

func on_modified_sn_gui_input(event: InputEvent):
	if isFinished:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var clickedIndex = get_char_index_at(modifiedSerNum, event.position.x)
	if clickedIndex == -1:
		return
	notify_interaction()
	var success = clickedIndex == differentIndex
	modifiedSerNum.add_theme_color_override("font_color", Color.GREEN if success else Color.RED)
	finish(success)
