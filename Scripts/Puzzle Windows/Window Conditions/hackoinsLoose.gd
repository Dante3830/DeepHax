class_name HackoinsLoose
extends PuzzleCondition

var waitingWindows = {}

func apply_cond(window: PuzzleWindow):
	waitingWindows[window] = true
	window.closed.connect(on_window_closed)
	window.tree_exiting.connect(on_window_exiting.bind(window))

func remove_cond(_window: PuzzleWindow):
	pass

func interaction(window: PuzzleWindow):
	waitingWindows.erase(window)

func on_window_closed(window: PuzzleWindow):
	if waitingWindows.erase(window):
		GameManager.add_hackoins(-GameManager.hackoins)

func on_window_exiting(window: PuzzleWindow):
	waitingWindows.erase(window)
