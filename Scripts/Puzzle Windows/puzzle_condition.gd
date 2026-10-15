class_name PuzzleCondition
extends Resource

@export var condition_icon: Texture2D
@export var condition_name = ""

func registry_key() -> String:
	var global_name: StringName = get_script().get_global_name()
	if global_name != &"":
		return String(global_name)
	return condition_name

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
