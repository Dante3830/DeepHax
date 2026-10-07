class_name Accelerator
extends PuzzleCondition

# Condición "Accelerator": acorta el tiempo total que tiene el jugador para
# resolver la ventana. Como el PlayerTimer de la ventana ya arrancó con su
# wait_time completo justo antes de que setup() llame a apply(), alcanza
# con achicarlo y reiniciarlo una sola vez acá.

@export_range(1.0, 3.0, 0.1) var speed_multiplier: float = 1.5
 
func apply(_window: PuzzleWindow) -> void:
	GameManager.time_speed_multiplier = speed_multiplier
 
func _on_remove(_window: PuzzleWindow) -> void:
	GameManager.time_speed_multiplier = 1.0
 
