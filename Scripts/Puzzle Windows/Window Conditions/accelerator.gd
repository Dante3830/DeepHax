class_name Accelerator
extends PuzzleCondition

@export var speed_options: Array[float] = [1.5, 2.0]

func _on_apply(window: PuzzleWindow) -> void:
	var multiplier: float = 1.5
	if not speed_options.is_empty():
		multiplier = speed_options.pick_random()
	GameManager.time_speed_multiplier = multiplier
	window.set_condition_time_text("x%.1f" % multiplier)

func _on_remove(_window: PuzzleWindow) -> void:
	GameManager.time_speed_multiplier = 1.0
