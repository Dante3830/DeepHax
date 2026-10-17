class_name Accelerator
extends PuzzleCondition

@export var speedMargin = [1.5, 2.0]

func apply_cond(_window: PuzzleWindow):
	var multiplier: float
	if !speedMargin.is_empty():
		multiplier = speedMargin.pick_random()
	GameManager.timeSpeed = multiplier

func remove_cond(_window: PuzzleWindow):
	GameManager.timeSpeed = 1.0
