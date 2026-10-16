class_name PuzzleWindow
extends Control

signal solved(window: PuzzleWindow, hackoin_reward: int)
signal failed(window: PuzzleWindow, time_penalty: float)
signal closed(window: PuzzleWindow)

const WARNING_HZ_START = 2.0
const WARNING_HZ_END = 6.0

@export var fail_time_penalty = 5.0
@export var base_hackoin_reward = 10
@export var condition_icon_size = 28.0
@export var warning_time = 5.0

var emerge_duration = 0.25

var minigame: PuzzleMinigame
var condition: PuzzleCondition

var _resolved = false
var _condition_applied = false

var _panel_style: StyleBoxFlat
var _base_bg_color: Color
var _warning_phase = 0.0

var _bounce_enabled = false
var _bounce_area: Rect2
var _bounce_velocity: Vector2
var _footprint: Rect2

@onready var content_container: Control = %ContentContainers
@onready var player_timer: Timer = $PlayerTimer
@onready var panel = $Panel
@onready var condition_panel = $ConditionPanel
@onready var condition_icon: Sprite2D = $ConditionPanel/Condition
@onready var condition_time_label = $ConditionPanel/Time

#region LIFECYCLE METHODS
func _ready():
	set_process(false)
	condition_time_label.visible = false
	condition_icon.position = Vector2(5.0, 5.0)
	
	var base_style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if base_style:
		_panel_style = base_style.duplicate()
		_base_bg_color = _panel_style.bg_color
		panel.add_theme_stylebox_override("panel", _panel_style)
	
	# La raíz mide 0x0, así que el centro se saca de lo que realmente se ve.
	_footprint = get_footprint()
	pivot_offset = _footprint.get_center()
	scale = Vector2.ZERO
	modulate.a = 0.0

func _process(delta: float):
	_update_warning(delta)
	if _bounce_enabled:
		_update_bounce(delta)

func _exit_tree():
	_release_condition()
#endregion

#region SETUP & CONFIGURATION
func setup(minigame_scene: PackedScene, condition_resource: PuzzleCondition = null, time_limit = 10.0):
	minigame = minigame_scene.instantiate()
	content_container.add_child(minigame)
	minigame.finished.connect(_resolve)
	minigame.interacted.connect(_on_minigame_interacted)
	
	condition_panel.visible = condition_resource != null
	if condition_resource:
		condition = condition_resource.duplicate()
		condition_icon.texture = condition.condition_icon
		_fit_condition_icon()
	
	await _emerge()
	
	if condition:
		condition.apply(self)
		_condition_applied = true
	
	player_timer.start(time_limit)
	set_process(true)
	minigame.start()

func enable_bounce(area: Rect2, speed: float):
	_bounce_enabled = true
	_bounce_area = area
	var angle := deg_to_rad(randf_range(25.0, 65.0)) + randi_range(0, 3) * (PI / 2.0)
	_bounce_velocity = Vector2.from_angle(angle) * speed
#endregion

#region FOOTPRINT & GEOMETRY
func get_footprint() -> Rect2:
	var rect := Rect2()
	var first := true
	for child in get_children():
		if child is Control:
			var child_rect := Rect2(child.position, child.size)
			rect = child_rect if first else rect.merge(child_rect)
			first = false
	return rect
#endregion

#region CONDITION TIME UI
func set_condition_time_text(text: String):
	condition_time_label.visible = true
	condition_time_label.text = text

func hide_condition_time():
	condition_time_label.visible = false
#endregion

#region EMERGE ANIMATION
func _emerge():
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE, emerge_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, emerge_duration)
	await tween.finished
#endregion

#region WARNING EFFECT
func _update_warning(delta: float):
	if _panel_style == null:
		return
	var time_left := player_timer.time_left
	if time_left > warning_time:
		return
	var urgency := 1.0 - clampf(time_left / maxf(warning_time, 0.001), 0.0, 1.0)
	_warning_phase += delta * lerpf(WARNING_HZ_START, WARNING_HZ_END, urgency)
	var pulse := (1.0 - cos(_warning_phase * TAU)) * 0.5
	_panel_style.bg_color = _base_bg_color.lerp(Color(0.75, 0.0, 0.0, 1.0), smoothstep(0.2, 0.8, pulse))
#endregion

#region BOUNCE MOVEMENT
func _update_bounce(delta: float):
	if _is_player_holding_click():
		return
	var min_pos := _bounce_area.position - _footprint.position
	var max_pos := (_bounce_area.end - _footprint.size - _footprint.position).max(min_pos)
	var pos := global_position + _bounce_velocity * delta
	for axis in [Vector2.AXIS_X, Vector2.AXIS_Y]:
		if pos[axis] <= min_pos[axis]:
			pos[axis] = min_pos[axis]
			_bounce_velocity[axis] = absf(_bounce_velocity[axis])
		elif pos[axis] >= max_pos[axis]:
			pos[axis] = max_pos[axis]
			_bounce_velocity[axis] = -absf(_bounce_velocity[axis])
	global_position = pos

# Mantener el clic sobre la ventana la frena, para poder "atraparla".
func _is_player_holding_click() -> bool:
	return Input.is_action_pressed("Click") and _footprint.has_point(get_local_mouse_position())
#endregion

#region CONDITION ICON FITTING
func _fit_condition_icon():
	var texture := condition_icon.texture
	if texture == null:
		push_warning("PuzzleWindow: la condición '%s' no tiene ícono (Condition Icon)." % condition.registry_key())
		return
	var limit := minf(condition_icon_size, minf(condition_panel.size.x, condition_panel.size.y))
	var longest_side := maxf(texture.get_size().x, texture.get_size().y)
	condition_icon.scale = Vector2.ONE * minf(1.0, limit / longest_side)
#endregion

#region TIMER & INTERACTION CALLBACKS
func _on_player_timer_timeout():
	_resolve(false)

func _on_minigame_interacted():
	if condition:
		condition.interaction(self)
#endregion

#region RESOLUTION & REWARD
func _resolve(success: bool):
	if _resolved:
		return
	_resolved = true
	set_process(false)
	if success:
		solved.emit(self, _calculate_reward())
	else:
		failed.emit(self, fail_time_penalty)
	_close()

# De 1x a 2x la recompensa base, según la fracción de tiempo que sobra.
func _calculate_reward() -> int:
	var time_fraction := player_timer.time_left / player_timer.wait_time
	return int(base_hackoin_reward * (1.0 + time_fraction))
#endregion

#region CLOSE & CLEANUP
func _close():
	player_timer.stop()
	_release_condition()
	closed.emit(self)
	queue_free()

func _release_condition():
	if _condition_applied:
		_condition_applied = false
		condition.remove(self)
#endregion
