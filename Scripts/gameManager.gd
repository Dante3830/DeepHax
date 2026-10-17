extends Node

signal hackoins_changed(total: int, delta: int)

var phase = 1
var linesCombo = 0
var hackoins = 0
var gameTime = 0.0

var timeSpeed = 1.0
var receiverLabel: CanvasItem = null
var activeConditions: Dictionary = {}
var keyboardLocked = false

# Transcurso de la partida
func new_game():
	hackoins = 0
	phase = 1
	linesCombo = 0
	gameTime = 0.0

func reset_conditions():
	timeSpeed = 1.0
	activeConditions.clear()
	keyboardLocked = false

# Hackoins
func add_hackoins(amount: int):
	hackoins += amount
	hackoins_changed.emit(hackoins, amount)

# Condiciones de las ventanas
func register_active_condition(conditionKey: String):
	activeConditions[conditionKey] = activeConditions.get(conditionKey, 0) + 1

func unregister_active_condition(conditionKey: String):
	if not activeConditions.has(conditionKey):
		return
	activeConditions[conditionKey] -= 1
	if activeConditions[conditionKey] <= 0:
		activeConditions.erase(conditionKey)

func is_condition_active(conditionKey: String) -> bool:
	return activeConditions.get(conditionKey, 0) > 0

# Funciones para el teclado
func lock_keyboard():
	keyboardLocked = true

func unlock_keyboard():
	keyboardLocked = false

func is_keyboard_locked() -> bool:
	return keyboardLocked
