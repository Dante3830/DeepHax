class_name PuzzleCondition
extends Resource

@export var conditionIcon: Texture2D
@export var conditionName = ""

func registry_key() -> String:
	var globalName: StringName = get_script().get_global_name()
	if globalName != &"":
		return String(globalName)
	return conditionName

func apply(window: PuzzleWindow):
	GameManager.register_active_condition(registry_key())
	apply_cond(window)

func remove(window: PuzzleWindow):
	remove_cond(window)
	GameManager.unregister_active_condition(registry_key())

func apply_cond(_window: PuzzleWindow):
	pass

func interaction(_window: PuzzleWindow):
	pass

func remove_cond(_window: PuzzleWindow):
	pass
