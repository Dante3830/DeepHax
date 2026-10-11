extends Camera2D

@export var max_shake: float = 10.0
@export var shake_fade: float = 10.0

var shake_strength: float = 0.0
var shake_axis: Vector2

func trigger_shake_both_exes() -> void:
	shake_strength = max_shake
	shake_axis = Vector2(1, 1)

func trigger_shake_x() -> void:
	shake_strength = max_shake
	shake_axis = Vector2(1, 0)

func trigger_shake_y() -> void:
	shake_strength = max_shake
	shake_axis = Vector2(0, 1)

func _process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, shake_fade * delta)
		offset = Vector2(randf_range(-shake_strength, shake_strength) * shake_axis.x, randf_range(-shake_strength, shake_strength) * shake_axis.y)
