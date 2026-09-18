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

signal solved
signal failed
signal interacted
