class_name KeyboardLock
extends PuzzleCondition

var keyboardIsLocked = false

func apply_cond(_window: PuzzleWindow) -> void:
	if GameManager.is_keyboard_locked():
		keyboardIsLocked = false
	else:
		GameManager.lock_keyboard()
		keyboardIsLocked = true

func remove_cond(_window: PuzzleWindow) -> void:
	if keyboardIsLocked:
		GameManager.unlock_keyboard()
		keyboardIsLocked = false
