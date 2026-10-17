# Todavía NO lo voy a usar
class_name TrapWindow
extends PuzzleCondition

@export var timePenalty = 20.0
@export var windowDuration = 5.0

var windowsWithTrap = {}

func apply_cond(window: PuzzleWindow):
	windowsWithTrap[window] = true
	tick(window, int(ceil(windowDuration)))

func remove_cond(window: PuzzleWindow):
	windowsWithTrap.erase(window)

func punish(window: PuzzleWindow):
	if windowsWithTrap.get(window, false):
		pass
		# Por acá pondré que, si el jugador interactúa, pierde segundos

func tick(window: PuzzleWindow, seconds_left: float):
	if not windowsWithTrap.get(window, false):
		return
	
	if seconds_left <= 0.0:
		windowsWithTrap.erase(window)
		window.hide_condition_time()
		return
	
	window.set_condition_time_text(str(seconds_left))
	var timer: SceneTreeTimer = window.get_tree().create_timer(1.0)
	timer.timeout.connect(tick.bind(window, seconds_left - 1.0))
