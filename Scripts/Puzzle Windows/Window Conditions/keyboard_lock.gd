class_name KeyboardLock
extends PuzzleCondition

var _was_locked_by_me: bool = false

func _on_apply(window: PuzzleWindow) -> void:
	if GameManager.is_keyboard_locked():
		_was_locked_by_me = false
	else:
		GameManager.lock_keyboard()
		_was_locked_by_me = true

func _on_remove(_window: PuzzleWindow) -> void:
	if _was_locked_by_me:
		GameManager.unlock_keyboard()
		_was_locked_by_me = false
