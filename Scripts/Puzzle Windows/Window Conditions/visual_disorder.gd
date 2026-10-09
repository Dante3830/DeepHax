class_name VisualDisorder
extends PuzzleCondition

const GLITCH_SHADER: Shader = preload("res://Shaders/glitch.gdshader")

@export_range(0.0, 1.0, 0.05) var intensity: float = 0.5
@export_range(0.1, 10.0, 0.1) var speed: float = 5.0

func _on_apply(_window: PuzzleWindow) -> void:
	var label: CanvasItem = GameManager.receiver_label
	if label == null:
		return

	var material := ShaderMaterial.new()
	material.shader = GLITCH_SHADER
	material.set_shader_parameter("intensity", intensity)
	material.set_shader_parameter("speed", speed)
	label.material = material

func _on_remove(_window: PuzzleWindow) -> void:
	var label: CanvasItem = GameManager.receiver_label
	if label:
		label.material = null
