class_name PerdidaDeHackoins
extends PuzzleCondition

## Condición "Pérdida de hackoins": si el jugador no interactúa con la
## ventana dentro de time_to_lose segundos, pierde todos sus hackoins.
## Muestra una cuenta regresiva en el label de tiempo de la condición.

@export var time_to_lose: float = 10.0

# window -> bool (sigue activa la cuenta regresiva para esa ventana).
# Guardado por ventana, no en una variable suelta, por si este mismo
# recurso terminara aplicado a más de una ventana a la vez.
var _active_windows: Dictionary = {}


func _on_apply(window: PuzzleWindow) -> void:
	_active_windows[window] = true
	_tick(window, int(ceil(time_to_lose)))


func _on_remove(window: PuzzleWindow) -> void:
	_active_windows.erase(window)


func on_interaction(window: PuzzleWindow) -> void:
	# El jugador interactuó a tiempo: se cancela la pérdida.
	_active_windows.erase(window)
	window.hide_condition_time()


func _tick(window: PuzzleWindow, seconds_left: int) -> void:
	if not _active_windows.get(window, false):
		return

	if seconds_left <= 0:
		_active_windows.erase(window)
		GameManager.add_hackoins(-GameManager.hackoins)
		return

	window.set_condition_time_text(str(seconds_left))
	var timer: SceneTreeTimer = window.get_tree().create_timer(1.0)
	timer.timeout.connect(_tick.bind(window, seconds_left - 1))
