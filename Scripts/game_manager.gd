extends Node

signal hackoins_changed(total: int, delta: int)

var phase = 1
var lines_combo = 0
var hackoins = 0
var game_time = 0.0

var time_speed = 1.0
var blocked_keys: Dictionary = {}
var receiver_label: CanvasItem = null
var active_conditions: Dictionary = {}
var keyboard_locked = false

# Transcurso de la partida
func new_game():
	hackoins = 0
	phase = 1
	lines_combo = 0
	game_time = 0.0

func reset_conditions():
	time_speed = 1.0
	blocked_keys.clear()
	active_conditions.clear()
	keyboard_locked = false

# Hackoins
func add_hackoins(amount: int):
	hackoins += amount
	hackoins_changed.emit(hackoins, amount)

# Condiciones de las ventanas
func register_active_condition(condition_key: String):
	active_conditions[condition_key] = active_conditions.get(condition_key, 0) + 1

func unregister_active_condition(condition_key: String):
	if not active_conditions.has(condition_key):
		return
	active_conditions[condition_key] -= 1
	if active_conditions[condition_key] <= 0:
		active_conditions.erase(condition_key)

func is_condition_active(condition_key: String) -> bool:
	return active_conditions.get(condition_key, 0) > 0

# Funciones para el teclado
func lock_keyboard():
	keyboard_locked = true

func unlock_keyboard():
	keyboard_locked = false

func is_keyboard_locked() -> bool:
	return keyboard_locked
