extends Camera2D

@export var max_shake: float = 10.0
@export var shake_fade: float = 10.0

var shake_strength: float = 0.0

func trigger_shake() -> void:
	shake_strength = max_shake

func _process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, shake_fade * delta)
		offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
