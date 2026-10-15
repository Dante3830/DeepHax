class_name ClockAdjust
extends PuzzleMinigame

@onready var panel: Panel = $Panel
@onready var clock_sprite = $CircleA
@onready var hour_needle = $Aguja1
@onready var minute_needle = $Aguja2
@onready var second_needle = $Aguja3
@onready var hours_text = $HH_MM_SS/HoursText
@onready var minutes_text = $HH_MM_SS/MinutesText
@onready var seconds_text = $HH_MM_SS/SecondsText

var target_hour = 1
var target_minute = 0
var target_second = 0

var dragging_needle = null
var first_input = true
var finished = false

func start():
	set_process(true)

func _ready():
	set_process(false)
	
	hour_needle.rotation = 0.0
	minute_needle.rotation = TAU / 3.0
	second_needle.rotation = 2.0 * TAU / 3.0
	
	target_hour = randi_range(1, 12)
	hours_text.text = "%02d" % target_hour
	target_minute = randi_range(0, 59)
	minutes_text.text = "%02d" % target_minute
	target_second = randi_range(0, 59)
	seconds_text.text = "%02d" % target_second

func _process(_delta: float):
	if finished:
		return
	
	var local_mouse: Vector2 = panel.get_local_mouse_position()
	
	if dragging_needle == null:
		var inside_clock := Rect2(Vector2.ZERO, panel.size).has_point(local_mouse)
		if inside_clock and Input.is_action_just_pressed("Click"):
			start_dragging(local_mouse)
		return
	
	var needle_angle = angle_from_center(local_mouse)
	var steps = 12 if dragging_needle == hour_needle else 60
	dragging_needle.rotation = snappedf(needle_angle, TAU / steps)
	
	if not Input.is_action_pressed("Click"):
		dragging_needle = null
		check_solved()

func start_dragging(local_pos: Vector2):
	var clock_angle := angle_from_center(local_pos)
	var candidates: Array[Node2D] = [hour_needle, minute_needle, second_needle]
	
	var closest: Node2D = candidates[0]
	var closest_diff: float = absf(angle_difference(clock_angle, closest.rotation))
	for needle in candidates:
		var diff = absf(angle_difference(clock_angle, needle.rotation))
		if diff < closest_diff:
			closest = needle
			closest_diff = diff
	
	dragging_needle = closest
	
	if first_input:
		first_input = false
		interacted.emit()

func check_solved():
	var hour_index = angle_to_index(hour_needle.rotation, 12)
	var minute_index = angle_to_index(minute_needle.rotation, 60)
	var second_index = angle_to_index(second_needle.rotation, 60)
	var target_hour_index = target_hour % 12
	
	if hour_index == target_hour_index and minute_index == target_minute and second_index == target_second:
		finished = true
		set_process(false)
		solved.emit()

func angle_from_center(local_pos: Vector2) -> float:
	var to_point : Vector2 = local_pos - clock_sprite.position
	return fposmod(to_point.angle() + PI / 2.0, TAU)

func angle_to_index(angle: float, steps: int) -> int:
	var step_size: float = TAU / steps
	return int(round(fposmod(angle, TAU) / step_size)) % steps
