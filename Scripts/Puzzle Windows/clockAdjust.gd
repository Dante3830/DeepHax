class_name ClockAdjust
extends PuzzleMinigame

const HOUR_STEPS = 12
const MINUTE_AND_SECOND_STEPS = 60

@onready var clockSprite = $CircleBase
@onready var hourNeedle = $HourNeedle
@onready var minuteNeedle = $MinuteNeedle
@onready var secondNeedle = $SecondNeedle
@onready var needles = [hourNeedle, minuteNeedle, secondNeedle]

@onready var hoursText = $HH_MM_SS/HoursText
@onready var minutesText = $HH_MM_SS/MinutesText
@onready var secondsText = $HH_MM_SS/SecondsText

var targetHour = 1
var targetMinute = 20
var targetSecond = 40
var needleDragged = null

func start():
	set_process(true)

func _ready():
	set_process(false)
	
	minuteNeedle.rotation = TAU / 3.0
	secondNeedle.rotation = 2.0 * TAU / 3.0
	
	targetHour = randi_range(1, HOUR_STEPS)
	hoursText.text = "%02d" % targetHour
	
	targetMinute = randi_range(0, MINUTE_AND_SECOND_STEPS - 1)
	minutesText.text = "%02d" % targetMinute
	
	targetSecond = randi_range(0, MINUTE_AND_SECOND_STEPS - 1)
	secondsText.text = "%02d" % targetSecond

func _process(_delta: float):
	var mouse = $Panel.get_local_mouse_position()
	
	if needleDragged == null:
		var inside_clock := Rect2(Vector2.ZERO, $Panel.size).has_point(mouse)
		if inside_clock and Input.is_action_just_pressed("Click"):
			move_needle(mouse)
		return
	
	var steps = HOUR_STEPS if needleDragged == hourNeedle else MINUTE_AND_SECOND_STEPS
	needleDragged.rotation = snappedf(angle_from_center(mouse), TAU / steps)
	
	if not Input.is_action_pressed("Click"):
		needleDragged = null
		all_needles_set()

func move_needle(mouse: Vector2):
	var clicked_angle = angle_from_center(mouse)
	var smallest_difference = INF
	for clock_needle in needles:
		var difference = absf(angle_difference(clicked_angle, clock_needle.rotation))
		if difference < smallest_difference:
			smallest_difference = difference
			needleDragged = clock_needle
	
	notify_interaction()

func all_needles_set():
	if (to_index(hourNeedle, HOUR_STEPS) == targetHour % HOUR_STEPS):
			if (to_index(minuteNeedle, MINUTE_AND_SECOND_STEPS) == targetMinute):
				if (to_index(secondNeedle, MINUTE_AND_SECOND_STEPS) == targetSecond):
					finish(true)

func angle_from_center(point: Vector2) -> float:
	return Vector2.UP.angle_to(point - clockSprite.position)

func to_index(needle: Node2D, steps: int) -> int:
	return roundi(fposmod(needle.rotation, TAU) / (TAU / steps)) % steps
