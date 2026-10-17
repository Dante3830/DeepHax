# Todavía NO lo voy a usar
class_name VisualDisorder
extends PuzzleCondition

@export_range(0.0, 1.0, 0.05) var intensity = 0.5
@export_range(0.1, 10.0, 0.1) var speed = 5.0

const GLITCH_SHADER = preload("res://Shaders/glitch.gdshader")

func apply_cond(_window: PuzzleWindow):
	var label: CanvasItem = GameManager.receiverLabel
	if label == null:
		return
	
	var material := ShaderMaterial.new()
	material.shader = GLITCH_SHADER
	material.set_shader_parameter("intensity", intensity)
	material.set_shader_parameter("speed", speed)
	label.material = material

func remove_cond(_window: PuzzleWindow):
	var label: CanvasItem = GameManager.receiverLabel
	if label:
		label.material = null
