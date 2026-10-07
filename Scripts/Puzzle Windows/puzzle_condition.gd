class_name PuzzleCondition
extends Resource

## Clase base para las condiciones de las ventanas-puzzle (Bloqueo de
## teclado, Acelerador, Desorden visual, Pérdida de hackoins, Trampa).
##
## IMPORTANTE: las condiciones concretas NO sobreescriben apply()/remove()
## directamente - sobreescriben _on_apply()/_on_remove(). La clase base usa
## apply()/remove() para registrar automáticamente la condición como
## "activa" en el GameManager mientras está aplicada, así quien elija
## condiciones al azar para una ventana nueva puede chequear
## GameManager.is_condition_active(nombre) y evitar poner la misma
## condición en dos ventanas a la vez.

@export var icon: Texture2D
@export var condition_name: String = ""

func apply(window: PuzzleWindow) -> void:
	GameManager.register_active_condition(_registry_key())
	_on_apply(window)

func remove(window: PuzzleWindow) -> void:
	_on_remove(window)
	GameManager.unregister_active_condition(_registry_key())

## Se llama cada vez que el jugador interactúa con el contenido de la
## ventana. Pensada para condiciones como "Trampa".
func on_interaction(_window: PuzzleWindow) -> void:
	pass

## Sobreescribir en cada condición concreta, en vez de apply().
func _on_apply(_window: PuzzleWindow) -> void:
	pass

## Sobreescribir en cada condición concreta, en vez de remove().
func _on_remove(_window: PuzzleWindow) -> void:
	pass

# Identificador único para el registro de "condiciones activas": usa el
# nombre de la clase (Acelerador, BloqueoDeTeclado, etc.) en vez de
# condition_name, así no depende de que completes ese campo a mano en
# cada .tres - viene solo.
func _registry_key() -> String:
	var global_name: StringName = get_script().get_global_name()
	if global_name != &"":
		return String(global_name)
	return condition_name
