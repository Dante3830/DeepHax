class_name ClockAdjust
extends PuzzleMinigame

const HOUR_STEPS = 12
const MINUTE_AND_SECOND_STEPS = 60

var target_hour = 1
var target_minute = 1
var target_second = 1
var dragged = null

@onready var clock_sprite = $CircleA
@onready var hour_needle = $Aguja1
@onready var minute_needle = $Aguja2
@onready var second_needle = $Aguja3
@onready var needles = [hour_needle, minute_needle, second_needle]

@onready var hours_text = $HH_MM_SS/HoursText
@onready var minutes_text = $HH_MM_SS/MinutesText
@onready var seconds_text = $HH_MM_SS/SecondsText

func start():
	set_process(true)

func _ready():
	set_process(false)
	
	minute_needle.rotation = TAU / 3.0
	second_needle.rotation = 2.0 * TAU / 3.0
	
	target_hour = randi_range(1, HOUR_STEPS)
	hours_text.text = "%02d" % target_hour
	
	target_minute = randi_range(0, MINUTE_AND_SECOND_STEPS - 1)
	minutes_text.text = "%02d" % target_minute
	
	target_second = randi_range(0, MINUTE_AND_SECOND_STEPS - 1)
	seconds_text.text = "%02d" % target_second

func _process(_delta: float):
	var mouse = $Panel.get_local_mouse_position()
	
	if dragged == null:
		var inside_clock := Rect2(Vector2.ZERO, $Panel.size).has_point(mouse)
		if inside_clock and Input.is_action_just_pressed("Click"):
			_grab_needle(mouse)
		return
	
	var steps = HOUR_STEPS if dragged == hour_needle else MINUTE_AND_SECOND_STEPS
	dragged.rotation = snappedf(_angle_from_center(mouse), TAU / steps)
	
	if not Input.is_action_pressed("Click"):
		dragged = null
		_check_solved()

func _grab_needle(mouse: Vector2):
	var click_angle := _angle_from_center(mouse)
	var smallest_diff := INF
	for needle in needles:
		var diff := absf(angle_difference(click_angle, needle.rotation))
		if diff < smallest_diff:
			smallest_diff = diff
			dragged = needle
	
	notify_interaction()

func _check_solved():
	if (_to_index(hour_needle, HOUR_STEPS) == target_hour % HOUR_STEPS
			and _to_index(minute_needle, MINUTE_AND_SECOND_STEPS) == target_minute
			and _to_index(second_needle, MINUTE_AND_SECOND_STEPS) == target_second):
		finish(true)

func _angle_from_center(point: Vector2) -> float:
	return Vector2.UP.angle_to(point - clock_sprite.position)

func _to_index(needle: Node2D, steps: int) -> int:
	return roundi(fposmod(needle.rotation, TAU) / (TAU / steps)) % steps
