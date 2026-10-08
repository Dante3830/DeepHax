extends Node

signal hackoins_changed(total: int, delta: int)

var phase = 1
var lines_combo = 0
var hackoins: int = 0
var game_time : float

var time_speed_multiplier: float = 1.0

var _blocked_keys: Dictionary = {}

var receiver_label: CanvasItem = null

var _active_conditions: Dictionary = {}

func add_hackoins(amount: int) -> void:
	hackoins += amount
	hackoins_changed.emit(hackoins, amount)

func is_key_blocked(keycode: int) -> bool:
	return _blocked_keys.has(keycode)

func block_key(keycode: int) -> void:
	_blocked_keys[keycode] = _blocked_keys.get(keycode, 0) + 1

func unblock_key(keycode: int) -> void:
	if not _blocked_keys.has(keycode):
		return
	_blocked_keys[keycode] -= 1
	if _blocked_keys[keycode] <= 0:
		_blocked_keys.erase(keycode)

func register_active_condition(condition_key: String) -> void:
	_active_conditions[condition_key] = _active_conditions.get(condition_key, 0) + 1

func unregister_active_condition(condition_key: String) -> void:
	if not _active_conditions.has(condition_key):
		return
	_active_conditions[condition_key] -= 1
	if _active_conditions[condition_key] <= 0:
		_active_conditions.erase(condition_key)

func is_condition_active(condition_key: String) -> bool:
	return _active_conditions.get(condition_key, 0) > 0

func reset_conditions() -> void:
	time_speed_multiplier = 1.0
	_blocked_keys.clear()
	_active_conditions.clear()

func change_scenes():
	pass

func new_game():
	hackoins = 0
	phase = 1
	lines_combo = 0
	game_time = 0.0
