# Todavía NO lo voy a usar
class_name HackoinsLoose
extends PuzzleCondition

@export var hackoinsPenalty = 10
var activeWindows = {}

func apply_cond(window: PuzzleWindow):
	activeWindows[window] = true
	tick(window, int(ceil(hackoinsPenalty)))

func remove_cond(window: PuzzleWindow):
	activeWindows.erase(window)

func interaction(window: PuzzleWindow):
	activeWindows.erase(window)
	window.hide_condition_time()

func tick(window: PuzzleWindow, secondsLeft: float):
	if not activeWindows.get(window, false):
		return
	
	if secondsLeft <= 0.0:
		activeWindows.erase(window)
		GameManager.add_hackoins(-GameManager.hackoins)
		return
	
	window.set_condition_time_text(str(secondsLeft))
	var timer = window.get_tree().create_timer(1.0)
	timer.timeout.connect(tick.bind(window, secondsLeft - 1))
