extends Node

signal hackoins_changed(total: int, delta: int)

var phase = 1
var lines_combo = 0
var hackoins: int = 0
var total_time

# Condición "Acelerador": multiplica la velocidad a la que se consume el
# tiempo de escribir la línea actual. 1.0 = velocidad normal.
var time_speed_multiplier: float = 1.0

# Condición "Bloqueo de teclado": mientras este contador sea mayor a 0, el
# TextEditor del nivel ignora CUALQUIER tecla (contador en vez de bool por
# si en algún momento hay más de una ventana con esta condición a la vez).
var _keyboard_block_count: int = 0

# Condición "Desorden visual": referencia al Label que muestra la línea a
# escribir, para poder aplicarle un shader de glitch mientras está activa.
# La asigna level_1.gd en su _ready().
var receiver_label: CanvasItem = null

# Condiciones actualmente aplicadas a alguna ventana-puzzle abierta, por
# nombre de clase, con cuántas ventanas la tienen activa (normalmente 0 o 1).
# Sirve para que quien elija condiciones al azar para una ventana nueva
# evite repetir la misma condición en dos ventanas a la vez.
var _active_conditions: Dictionary = {}

func add_hackoins(amount: int) -> void:
	hackoins += amount
	hackoins_changed.emit(hackoins, amount)

func is_key_blocked(_keycode: int) -> bool:
	return _keyboard_block_count > 0

func block_keyboard() -> void:
	_keyboard_block_count += 1

func unblock_keyboard() -> void:
	_keyboard_block_count = max(0, _keyboard_block_count - 1)

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

func new_game():
	pass
