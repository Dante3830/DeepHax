class_name PuzzleWindow
extends Control

signal solved(window: PuzzleWindow, hackoin_reward: int)
signal failed(window: PuzzleWindow, time_penalty: float)
signal closed(window: PuzzleWindow)

@export var fail_time_penalty: float = 5.0
@export var base_hackoin_reward: int = 10
@export var emerge_duration: float = 0.25

@export var condition_icon_size: float = 28.0

@export var warning_time: float = 5.0
@export var warning_color: Color = Color(0.8, 0.0, 0.0)

const WARNING_HZ_START: float = 2.0
const WARNING_HZ_END: float = 6.0

@onready var content_container: Control = %ContentContainer
@onready var player_timer: Timer = $PlayerTimer
@onready var panel: Panel = $Panel
@onready var condition_panel: Panel = $ConditionPanel
@onready var condition_icon: Sprite2D = $ConditionPanel/Condition
@onready var condition_time_label: Label = $ConditionPanel/Time

var minigame: PuzzleMinigame = null
var condition: PuzzleCondition = null

var _resolved: bool = false

var _condition_applied: bool = false

# --- Titileo rojo ---
var _panel_style: StyleBoxFlat = null
var _base_bg_color: Color = Color.BLACK
var _warning_phase: float = 0.0

# --- Rebote en la pantalla ---
var _active: bool = false
var _bounce_enabled: bool = false
var _bounce_area: Rect2 = Rect2()
var _bounce_velocity: Vector2 = Vector2.ZERO
var _footprint: Rect2 = Rect2()

func _ready() -> void:
	condition_icon.visible = false
	condition_time_label.visible = false
	
	player_timer.stop()
	player_timer.one_shot = true
	
	var base_style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if base_style:
		_panel_style = base_style.duplicate()
		_base_bg_color = _panel_style.bg_color
		panel.add_theme_stylebox_override("panel", _panel_style)
	else:
		push_warning("PuzzleWindow: el Panel no tiene un StyleBoxFlat; no habrá titileo rojo.")
	
	pivot_offset = size / 2.0
	scale = Vector2.ZERO
	modulate.a = 0.0

func setup(minigame_scene: PackedScene, condition_resource: PuzzleCondition = null, time_limit: float = 10.0) -> void:
	minigame = minigame_scene.instantiate()
	content_container.add_child(minigame)
	minigame.solved.connect(_on_minigame_solved)
	minigame.failed.connect(_on_minigame_failed)
	minigame.interacted.connect(_on_minigame_interacted)
	
	condition_panel.visible = condition_resource != null
	if condition_resource:
		condition = condition_resource.duplicate()
		condition_icon.visible = true
		condition_icon.texture = condition.icon
		_fit_condition_icon()
	
	await _emerge()
	_footprint = get_footprint()
	_active = true
	
	if condition:
		condition.apply(self)
		_condition_applied = true
	
	player_timer.wait_time = time_limit
	player_timer.start()
	minigame.start()

func _emerge() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, emerge_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, emerge_duration)
	await tween.finished

func enable_bounce(area: Rect2, speed: float) -> void:
	_bounce_enabled = true
	_bounce_area = area
	# Dirección en diagonal: los ángulos casi horizontales o verticales
	# rebotan siempre entre las mismas dos paredes y se ven aburridos.
	var angle := deg_to_rad(randf_range(25.0, 65.0)) + randi_range(0, 3) * (PI / 2.0)
	_bounce_velocity = Vector2.from_angle(angle) * speed

func _process(delta: float) -> void:
	if not _active or _resolved:
		return
	_update_warning(delta)
	if _bounce_enabled:
		_update_bounce(delta)

func _update_warning(delta: float) -> void:
	if _panel_style == null or player_timer.is_stopped():
		return
	var time_left := player_timer.time_left
	if time_left > warning_time:
		return
	var urgency := 1.0 - clampf(time_left / maxf(warning_time, 0.001), 0.0, 1.0)
	_warning_phase += delta * lerpf(WARNING_HZ_START, WARNING_HZ_END, urgency)
	var pulse := (1.0 - cos(_warning_phase * TAU)) * 0.5  # 0 (negro) .. 1 (rojo)
	_panel_style.bg_color = _base_bg_color.lerp(warning_color, smoothstep(0.2, 0.8, pulse))

func _update_bounce(delta: float) -> void:
	if _is_player_holding_click():
		return
	var min_pos := _bounce_area.position - _footprint.position
	var max_pos := (_bounce_area.end - _footprint.size - _footprint.position).max(min_pos)
	var pos := global_position + _bounce_velocity * delta
	if pos.x <= min_pos.x:
		pos.x = min_pos.x
		_bounce_velocity.x = absf(_bounce_velocity.x)
	elif pos.x >= max_pos.x:
		pos.x = max_pos.x
		_bounce_velocity.x = -absf(_bounce_velocity.x)
	if pos.y <= min_pos.y:
		pos.y = min_pos.y
		_bounce_velocity.y = absf(_bounce_velocity.y)
	elif pos.y >= max_pos.y:
		pos.y = max_pos.y
		_bounce_velocity.y = -absf(_bounce_velocity.y)
	global_position = pos

func _is_player_holding_click() -> bool:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return false
	var rect := Rect2(global_position + _footprint.position, _footprint.size)
	return rect.has_point(get_global_mouse_position())

func get_footprint() -> Rect2:
	var rect := Rect2()
	var first := true
	for child in get_children():
		if child is Control:
			var child_rect := Rect2(child.position, child.size)
			rect = child_rect if first else rect.merge(child_rect)
			first = false
	return rect

func _fit_condition_icon() -> void:
	if condition_icon.texture == null:
		#push_warning("PuzzleWindow: la condición '%s' no tiene ícono." % ...)
		condition_icon.visible = false
		return
	var texture_size: Vector2 = condition_icon.texture.get_size()
	var longest_side: float = maxf(texture_size.x, texture_size.y)
	if longest_side <= 0.0:
		return
	condition_icon.scale = Vector2.ONE * minf(1.0, condition_icon_size / longest_side)

func set_condition_time_text(text: String) -> void:
	condition_time_label.visible = true
	condition_time_label.text = text

func hide_condition_time() -> void:
	condition_time_label.visible = false

func _on_player_timer_timeout() -> void:
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

func _calculate_reward(elapsed_seconds: float) -> int:
	var speed_bonus: float = clamp(1.0 - (elapsed_seconds / player_timer.wait_time), 0.0, 1.0)
	return int(base_hackoin_reward * (1.0 + speed_bonus))

func _close() -> void:
	_release_condition()
	closed.emit(self)
	queue_free()

func _exit_tree() -> void:
	_release_condition()

func _release_condition() -> void:
	if condition and _condition_applied:
		_condition_applied = false
		condition.remove(self)
