class_name PuzzleMinigame
extends Control

## Clase base para los microjuegos (Simón Dice, Mantener Pulsado,
## Conexión de cables, Igualar cuadros 3x3, Ajustar reloj, etc).
##
## Cada microjuego concreto hereda de esta clase y solo necesita:
##   1) Armar su propia UI en la escena.
##   2) Emitir `solved` cuando el jugador lo resuelve.
##   3) Emitir `failed` si el jugador falla (ej: "No pulsar" al hacer click).
##   4) Emitir `interacted` en la primera interacción del jugador (usado por
##      condiciones como Trampa; si tu microjuego no lo necesita, no pasa nada
##      con no emitirla nunca).
##   5) Opcionalmente sobreescribir `start()`: es lo que llama PuzzleWindow
##      justo después de que la ventana termina de emerger. Si tu microjuego
##      no necesita una intro propia, no hace falta tocar nada: queda como
##      no-op y PuzzleWindow lo va a llamar igual sin romper nada.

signal solved
signal failed
signal interacted

## Llamado por PuzzleWindow apenas termina su animación de aparición.
## Sobreescribilo en los microjuegos que necesiten una intro propia
## (ej: Simón Dice revelando los botones antes de arrancar la secuencia).
func start() -> void:
	pass
