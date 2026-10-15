class_name KeyboardLock
extends PuzzleCondition

var keyboard_is_locked = false

func apply_cond(_window: PuzzleWindow) -> void:
	if GameManager.is_keyboard_locked():
		keyboard_is_locked = false
	else:
		GameManager.lock_keyboard()
		keyboard_is_locked = true

func remove_cond(_window: PuzzleWindow) -> void:
	if keyboard_is_locked:
		GameManager.unlock_keyboard()
		keyboard_is_locked = false
