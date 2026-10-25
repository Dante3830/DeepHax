class_name ZoneSlider
extends PuzzleMinigame

@onready var slider = $HSlider
@onready var zoneRect = $ZoneRect

var zoneStart = 0.0
var zoneWidth = 0.0
var zoneEnd = 0.0
var sweepTime = 0.0
var openTime = 0.0
var running = false

func _ready():
	slider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zoneWidth = randf_range(16.0, 22.0)
	zoneStart = randf_range(10.0, maxf(10.0, 90.0 - zoneWidth))
	zoneEnd = zoneStart + zoneWidth
	sweepTime = randf_range(0.0, 2.0) / 1.0
	build_zone()
	if get_tree().current_scene == self:
		start()

func start():
	running = true
	openTime = 0.0

func _process(delta: float):
	if !running:
		return
	openTime += delta
	sweepTime += delta
	slider.value = pingpong(sweepTime * 1.0, 1.0) * 100.0

func build_zone():
	zoneRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grabberWidth = slider.get_theme_icon("grabber").get_width()
	var usable = slider.size.x - grabberWidth
	var totalRange = slider.max_value - slider.min_value
	var startX = slider.position.x + grabberWidth / 2.0 + usable * (zoneStart - slider.min_value) / totalRange
	var endX = slider.position.x + grabberWidth / 2.0 + usable * (zoneEnd - slider.min_value) / totalRange
	zoneRect.position = Vector2(startX, slider.position.y)
	zoneRect.size = Vector2(endX - startX, slider.size.y)

func on_panel_gui_input(event: InputEvent):
	if isFinished or !running or openTime < 0.25:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		notify_interaction()
		var success = slider.value >= zoneStart and slider.value <= zoneEnd
		slider.modulate = Color.GREEN if success else Color.RED
		finish(success)
