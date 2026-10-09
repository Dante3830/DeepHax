class_name TrapWindow
extends PuzzleCondition

@export var trap_duration: float = 5.0
@export var hackoin_penalty: int = 20

var _trapped_windows: Dictionary = {}

func _on_apply(window: PuzzleWindow) -> void:
	_trapped_windows[window] = true
	_tick(window, int(ceil(trap_duration)))

func _on_remove(window: PuzzleWindow) -> void:
	_trapped_windows.erase(window)

func on_interaction(window: PuzzleWindow) -> void:
	if _trapped_windows.get(window, false):
		GameManager.add_hackoins(-min(hackoin_penalty, GameManager.hackoins))

func _tick(window: PuzzleWindow, seconds_left: int) -> void:
	if not _trapped_windows.get(window, false):
		return
	
	if seconds_left <= 0:
		_trapped_windows.erase(window)
		window.hide_condition_time()
		return
	
	window.set_condition_time_text(str(seconds_left))
	var timer: SceneTreeTimer = window.get_tree().create_timer(1.0)
	timer.timeout.connect(_tick.bind(window, seconds_left - 1))
