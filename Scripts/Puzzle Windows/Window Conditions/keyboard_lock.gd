class_name KeyboardLock
extends PuzzleCondition

@export var blockable_keys: Array[int] = [
	KEY_A, KEY_E, KEY_I, KEY_O, KEY_S, KEY_T, KEY_R, KEY_N, KEY_C, KEY_ENTER
]

# Cada ventana recibe su propia copia de esta condición (ver
# PuzzleWindow.setup), así que este estado no se mezcla entre ventanas.
var _blocked_key: int = KEY_NONE

func _on_apply(window: PuzzleWindow) -> void:
	if blockable_keys.is_empty():
		return
	_blocked_key = blockable_keys.pick_random()
	GameManager.block_key(_blocked_key)
	window.set_condition_time_text(OS.get_keycode_string(_blocked_key))

func _on_remove(_window: PuzzleWindow) -> void:
	if _blocked_key == KEY_NONE:
		return
	GameManager.unblock_key(_blocked_key)
	_blocked_key = KEY_NONE
