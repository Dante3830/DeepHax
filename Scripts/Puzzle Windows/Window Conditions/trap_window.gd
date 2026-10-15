# Todavía NO es usado
class_name TrapWindow
extends PuzzleCondition

@export var time_penalty: float = 20.0
@export var window_duration: float = 5.0

var windows_with_trap: Dictionary = {}

func apply_cond(window: PuzzleWindow):
	windows_with_trap[window] = true
	tick(window, int(ceil(window_duration)))

func remove_cond(window: PuzzleWindow):
	windows_with_trap.erase(window)

func punish(window: PuzzleWindow):
	if windows_with_trap.get(window, false):
		pass
		# Por acá pondré que, si el jugador interactúa, pierde segundos

func tick(window: PuzzleWindow, seconds_left: float):
	if not windows_with_trap.get(window, false):
		return
	
	if seconds_left <= 0.0:
		windows_with_trap.erase(window)
		window.hide_condition_time()
		return
	
	window.set_condition_time_text(str(seconds_left))
	var timer: SceneTreeTimer = window.get_tree().create_timer(1.0)
	timer.timeout.connect(tick.bind(window, seconds_left - 1.0))
