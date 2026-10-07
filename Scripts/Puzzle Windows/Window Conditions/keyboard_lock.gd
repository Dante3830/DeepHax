class_name KeyboardLock
extends PuzzleCondition

## Condición "Bloqueo de teclado": mientras la ventana está abierta, el
## TextEditor del nivel ignora CUALQUIER tecla (ver GameManager.is_key_blocked(),
## usado en level_1.gd antes de procesar Tab, Enter o cualquier otra tecla).

func _on_apply(_window: PuzzleWindow) -> void:
	GameManager.block_keyboard()

func _on_remove(_window: PuzzleWindow) -> void:
	GameManager.unblock_keyboard()
