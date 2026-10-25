class_name ZoneSlider
extends PuzzleMinigame

@export var sweepsPerSecond = 1.0 # recorridos de un extremo al otro por segundo
@export var zoneWidth = 22.0 # ancho de la zona verde, en % del recorrido
@export var inputGrace = 0.25 # segundos tras start() en los que se ignoran los clics

@onready var panel: Panel = $Panel
@onready var slider: HSlider = $HSlider

var zoneStart = 0.0
var zoneEnd = 0.0
var sweepTime = 0.0
var openTime = 0.0
var running = false
var zoneRect: ColorRect

func _ready() -> void:
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 0.1
	slider.mouse_filter = Control.MOUSE_FILTER_IGNORE # así los clics llegan al Panel
	zoneStart = randf_range(10.0, maxf(10.0, 90.0 - zoneWidth))
	zoneEnd = zoneStart + zoneWidth
	sweepTime = randf_range(0.0, 2.0) / sweepsPerSecond # arranca en un punto al azar
	build_zone()
	panel.gui_input.connect(on_panel_gui_input)
	# Al probar la escena sola (F6) nadie llama a start(), así que arranca por su cuenta.
	if get_tree().current_scene == self:
		start()

func start() -> void:
	running = true
	openTime = 0.0

func _process(delta: float) -> void:
	if not running:
		return
	openTime += delta
	sweepTime += delta
	slider.value = pingpong(sweepTime * sweepsPerSecond, 1.0) * 100.0

# Dibuja la zona verde detrás del slider, alineada con el centro del indicador.
func build_zone() -> void:
	zoneRect = ColorRect.new()
	zoneRect.color = Color(0.0, 1.0, 0.0, 0.45)
	zoneRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(zoneRect)
	move_child(zoneRect, slider.get_index())
	var grabberWidth = slider.get_theme_icon("grabber").get_width()
	var usable = slider.size.x - grabberWidth
	var totalRange = slider.max_value - slider.min_value
	var startX = slider.position.x + grabberWidth / 2.0 + usable * (zoneStart - slider.min_value) / totalRange
	var endX = slider.position.x + grabberWidth / 2.0 + usable * (zoneEnd - slider.min_value) / totalRange
	zoneRect.position = Vector2(startX, slider.position.y)
	zoneRect.size = Vector2(endX - startX, slider.size.y)

func on_panel_gui_input(event: InputEvent) -> void:
	if isFinished or not running or openTime < inputGrace:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		notify_interaction()
		var success = slider.value >= zoneStart and slider.value <= zoneEnd
		slider.modulate = Color.GREEN if success else Color.RED
		finish(success)
