class_name PuzzleCondition
extends Resource

@export var icon: Texture2D
@export var condition_name: String = ""

func apply(window: PuzzleWindow) -> void:
	GameManager.register_active_condition(_registry_key())
	_on_apply(window)

func remove(window: PuzzleWindow) -> void:
	_on_remove(window)
	GameManager.unregister_active_condition(_registry_key())

func on_interaction(_window: PuzzleWindow) -> void:
	pass

func _on_apply(_window: PuzzleWindow) -> void:
	pass

func _on_remove(_window: PuzzleWindow) -> void:
	pass

func _registry_key() -> String:
	var global_name: StringName = get_script().get_global_name()
	if global_name != &"":
		return String(global_name)
	return condition_name
