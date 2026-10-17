class_name PuzzleWindow
extends Control

signal solved(window: PuzzleWindow, hackoin_reward: int)
signal failed(window: PuzzleWindow, time_penalty: float)
signal closed(window: PuzzleWindow)

const WARNING_START = 2.0
const WARNING_END = 6.0

@export var failTime = 5.0
@export var baseHackoinReward = 10
@export var warningTime = 5.0

@onready var contentContainer = %ContentContainer
@onready var playerTimer: Timer = $PlayerTimer
@onready var panel = $Panel
@onready var conditionPanel = $ConditionPanel
@onready var conditionIcon: Sprite2D = $ConditionPanel/Condition

var emergeDuration = 0.25
var conditionIconSize = 28.0

var minigame: PuzzleMinigame
var condition: PuzzleCondition

var resolved = false
var conditionApplied = false

var panelStyle: StyleBoxFlat
var baseBGColor: Color
var warningPhase = 0.0

var bounceEnabled = false
var bounceArea: Rect2
var bounceVelocity: Vector2
var footprint: Rect2

func _ready():
	set_process(false)
	conditionIcon.position = Vector2(15.0, 15.0)
	
	panelStyle = panel.get_theme_stylebox("panel")
	baseBGColor = panelStyle.bg_color
	
	footprint = get_footprint()
	pivot_offset = footprint.get_center()
	scale = Vector2.ZERO

func _process(delta: float):
	if bounceEnabled:
		if not is_player_holding_click():
			var minPos := bounceArea.position - footprint.position
			var maxPos := (bounceArea.end - footprint.size - footprint.position).max(minPos)
			var pos := global_position + bounceVelocity * delta
			for axis in [Vector2.AXIS_X, Vector2.AXIS_Y]:
				if pos[axis] <= minPos[axis]:
					pos[axis] = minPos[axis]
					bounceVelocity[axis] = absf(bounceVelocity[axis])
				elif pos[axis] >= maxPos[axis]:
					pos[axis] = maxPos[axis]
					bounceVelocity[axis] = -absf(bounceVelocity[axis])
			global_position = pos
	
	if panelStyle == null:
		return
	var timeLeft := playerTimer.time_left
	if timeLeft > warningTime:
		return
	var urgency := 1.0 - clampf(timeLeft / maxf(warningTime, 0.001), 0.0, 1.0)
	warningPhase += delta * lerpf(WARNING_START, WARNING_END, urgency)
	var pulse := (1.0 - cos(warningPhase * TAU)) * 0.5
	panelStyle.bg_color = baseBGColor.lerp(Color(0.75, 0.0, 0.0), smoothstep(0.2, 0.8, pulse))

func _exit_tree():
	if conditionApplied:
		conditionApplied = false
		condition.remove(self)

func setup(minigameScene: PackedScene, conditionResource: PuzzleCondition = null, timeLimit = 10.0):
	minigame = minigameScene.instantiate()
	contentContainer.add_child(minigame)
	minigame.finished.connect(resolve)
	minigame.interacted.connect(on_minigame_interacted)
	
	conditionPanel.visible = conditionResource != null
	if conditionResource:
		condition = conditionResource.duplicate()
		conditionIcon.texture = condition.conditionIcon
		var limit := minf(conditionIconSize, minf(conditionPanel.size.x, conditionPanel.size.y))
		var longestSide := maxf(conditionIcon.texture.get_size().x, conditionIcon.texture.get_size().y)
		conditionIcon.scale = Vector2.ONE * minf(1.0, limit / longestSide)
	
	await emerge_animation()
	
	if condition:
		condition.apply(self)
		conditionApplied = true
	
	playerTimer.start(timeLimit)
	set_process(true)
	minigame.start()

func enable_bounce(area: Rect2, speed: float):
	bounceEnabled = true
	bounceArea = area
	var angle := deg_to_rad(randf_range(25.0, 65.0)) + randi_range(0, 3) * (PI / 2.0)
	bounceVelocity = Vector2.from_angle(angle) * speed

func get_footprint() -> Rect2:
	var rect := Rect2()
	var first := true
	for child in get_children():
		if child is Control:
			var child_rect := Rect2(child.position, child.size)
			rect = child_rect if first else rect.merge(child_rect)
			first = false
	return rect

func emerge_animation():
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, emergeDuration)
	await tween.finished

func on_minigame_interacted():
	if condition:
		condition.interaction(self)

func resolve(success: bool):
	if resolved:
		return
	resolved = true
	set_process(false)
	if success:
		solved.emit(self, calculate_reward())
	else:
		failed.emit(self, failTime)
	playerTimer.stop()
	if conditionApplied:
		conditionApplied = false
		condition.remove(self)
	closed.emit(self)
	queue_free()

func calculate_reward() -> int:
	var timeFraction := playerTimer.time_left / playerTimer.wait_time
	return int(baseHackoinReward * (1.0 + timeFraction))

func is_player_holding_click() -> bool:
	return Input.is_action_pressed("Click") and footprint.has_point(get_local_mouse_position())

func _on_player_timer_timeout():
	resolve(false)
