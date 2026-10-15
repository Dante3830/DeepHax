class_name Accelerator
extends PuzzleCondition

@export var speed_margin = [1.5, 2.0]

func apply_cond(_window: PuzzleWindow):
	var multiplier: float
	if !speed_margin.is_empty():
		multiplier = speed_margin.pick_random()
	GameManager.time_speed = multiplier

func remove_cond(_window: PuzzleWindow):
	GameManager.time_speed = 1.0
