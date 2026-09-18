class_name PuzzleCondition
extends Resource

## Clase base para las condiciones de las ventanas-puzzle
## (Bloqueo de teclado, Acelerador, Desorden visual, Pérdida de hackoins, Trampa).
## Cada condición concreta hereda de esta y sobreescribe los métodos que necesite.
## Al ser un Resource, podés crear un .tres por condición y asignarlo desde
## el spawner sin tocar código.

@export var icon: Texture2D
@export var condition_name: String = ""

## Se llama una sola vez, cuando la ventana se abre.
func apply(_window: PuzzleWindow) -> void:
	pass

## Se llama cuando la ventana se cierra (resuelta o fallada).
## Usar para desconectar timers, sacar shaders, restaurar teclas, etc.
func remove(_window: PuzzleWindow) -> void:
	pass

## Se llama cada vez que el jugador interactúa con el contenido de la ventana.
## Pensada para condiciones como "Trampa" (penalizar si se toca en los primeros 5s).
func on_interaction(_window: PuzzleWindow) -> void:
	pass
