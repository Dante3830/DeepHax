class_name PuzzleWindow
extends Control

## Ventana-puzzle genérica. Orquesta un microjuego (PuzzleMinigame) y,
## opcionalmente, una condición (PuzzleCondition), usando el PlayerTimer
## de la escena como límite de tiempo para fallar automáticamente.

signal solved(window: PuzzleWindow, hackoin_reward: int)
signal failed(window: PuzzleWindow, time_penalty: float)
signal closed(window: PuzzleWindow)

@export var fail_time_penalty: float = 5.0
@export var base_hackoin_reward: int = 10
@export var emerge_duration: float = 0.25  # cuánto tarda en aparecer la ventana

@onready var content_container: Control = %ContentContainer
@onready var player_timer: Timer = $PlayerTimer
@onready var condition_panel: Panel = $ConditionPanel
@onready var condition_icon: Sprite2D = $ConditionPanel/Condition
@onready var condition_time_label: Label = $ConditionPanel/Time

var minigame: PuzzleMinigame = null
var condition: PuzzleCondition = null

var _resolved: bool = false

func _ready() -> void:
	condition_icon.visible = false
	condition_time_label.visible = false

	# Ocultar la ventana hasta que setup() la haga emerger. Si tu Control
	# raíz no queda centrado al escalar, ajustá pivot_offset a mano en el
	# editor (debería ser la mitad de tu tamaño real).
	pivot_offset = size / 2.0
	scale = Vector2.ZERO
	modulate.a = 0.0

# Llamado por el spawner justo después de instanciar la ventana.
# time_limit es cuánto tarda en fallar sola si el jugador no hace nada
# (ajustalo distinto para cada tipo de microjuego: Simón Dice necesita
# más que Mantener Pulsado, por ejemplo). El cronómetro arranca recién
# cuando la ventana termina de emerger, no antes.
func setup(minigame_scene: PackedScene, condition_resource: PuzzleCondition = null, time_limit: float = 10.0) -> void:
	minigame = minigame_scene.instantiate()
	content_container.add_child(minigame)
	minigame.solved.connect(_on_minigame_solved)
	minigame.failed.connect(_on_minigame_failed)
	minigame.interacted.connect(_on_minigame_interacted)

	if condition_resource:
		condition = condition_resource
		condition_icon.visible = true
		condition_icon.texture = condition.icon
		condition.apply(self)

	await _emerge()

	player_timer.wait_time = time_limit
	player_timer.start()
	minigame.start()

# Animación de aparición de la ventana entera (contenido + panel de
# condición incluidos): crece desde el centro y se desvanece hacia
# adentro. El microjuego arranca su propia intro (start()) recién
# cuando esto termina.
func _emerge() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, emerge_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, emerge_duration)
	await tween.finished

## API para que una PuzzleCondition muestre su propia cuenta regresiva
## (ej: Trampa mostrando "5", Pérdida de hackoins mostrando "10").
func set_condition_time_text(text: String) -> void:
	condition_time_label.visible = true
	condition_time_label.text = text

func hide_condition_time() -> void:
	condition_time_label.visible = false

func _on_player_timer_timeout() -> void:
	# El jugador no resolvió a tiempo: cuenta como fallo.
	_on_minigame_failed()

func _on_minigame_solved() -> void:
	if _resolved:
		return
	_resolved = true
	var elapsed := player_timer.wait_time - player_timer.time_left
	player_timer.stop()
	var reward := _calculate_reward(elapsed)
	solved.emit(self, reward)
	_close()

func _on_minigame_failed() -> void:
	if _resolved:
		return
	_resolved = true
	player_timer.stop()
	failed.emit(self, fail_time_penalty)
	_close()

func _on_minigame_interacted() -> void:
	if condition:
		condition.on_interaction(self)

# Más rápido lo resuelve el jugador (relativo al tiempo límite de esta
# ventana), más hackoins se lleva.
func _calculate_reward(elapsed_seconds: float) -> int:
	var speed_bonus: float = clamp(1.0 - (elapsed_seconds / player_timer.wait_time), 0.0, 1.0)
	return int(base_hackoin_reward * (1.0 + speed_bonus))

func _close() -> void:
	if condition:
		condition.remove(self)
	closed.emit(self)
	queue_free()
