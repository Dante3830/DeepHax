# Todavía NO es usado
class_name HackoinsLoose
extends PuzzleCondition

@export var hackoins_penalty = 10
var active_windows: Dictionary = {}

func apply_cond(window: PuzzleWindow):
	active_windows[window] = true
	tick(window, int(ceil(hackoins_penalty)))

func remove_cond(window: PuzzleWindow):
	active_windows.erase(window)

func interaction(window: PuzzleWindow):
	active_windows.erase(window)
	window.hide_condition_time()

func tick(window: PuzzleWindow, seconds_left: int):
	if not active_windows.get(window, false):
		return
	
	if seconds_left <= 0:
		active_windows.erase(window)
		GameManager.add_hackoins(-GameManager.hackoins)
		return
	
	window.set_condition_time_text(str(seconds_left))
	var timer = window.get_tree().create_timer(1.0)
	timer.timeout.connect(tick.bind(window, seconds_left - 1))
