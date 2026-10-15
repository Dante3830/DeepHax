class_name CablesConnect
extends PuzzleMinigame

class CablePair:
	var start: Panel
	var end: Panel
	var line: Line2D
	var connected := false

@onready var variations = [$Variation1, $Variation2, $Variation3]

var _pairs: Array[Dictionary] = []

var active_variation: Control = null
var dragging_index = -1
var first_input = true
var finished = false

func _ready():
	set_process(false)
	
	var variation_index = -1
	if variation_index < 0 or variation_index >= variations.size():
		variation_index = randi() % variations.size()
	
	active_variation = variations[variation_index]
	for variation in variations:
		variation.visible = (variation == active_variation)
	
	_pairs = _build_pairs(active_variation)

func start():
	set_process(true)

func _build_pairs(variation: Control) -> Array[Dictionary]:
	var left_panels: Array[Panel] = []
	var right_panels: Array[Panel] = []
	var areas: Array[Area2D] = []
	
	for child in variation.get_children():
		if child is Panel:
			if child.name.begins_with("PointA"):
				left_panels.append(child)
			elif child.name.begins_with("PointB"):
				right_panels.append(child)
		elif child is Area2D:
			areas.append(child)
	
	var pairs: Array[Dictionary] = []
	for left_panel in left_panels:
		var left_color: Color = _panel_color(left_panel)
		var right_panel: Panel = _find_matching_panel(left_color, right_panels)
		if right_panel == null:
			print("[ConexionCables] ADVERTENCIA: no encontré PointB con el mismo color que ", left_panel.name)
			continue
		
		var left_area: Area2D = _closest_area(left_panel, areas)
		var right_area: Area2D = _closest_area(right_panel, areas)
		
		var left_area_pos: Vector2 = left_area.position
		var left_hit_pos: Vector2 = _area_center(left_area)
		var right_hit_pos: Vector2 = _area_center(right_area)
		var line_origin: Vector2 = left_hit_pos - left_area_pos
		
		var line: Line2D = _get_or_create_line(left_area)
		line.clear_points()
		line.add_point(line_origin)
		line.add_point(line_origin)
		
		pairs.append({
			"line": line,
			"line_origin": line_origin,
			"left_area_pos": left_area_pos,
			"left_hit_pos": left_hit_pos,
			"left_radius": _area_radius(left_area),
			"right_hit_pos": right_hit_pos,
			"right_radius": _area_radius(right_area),
			"connected": false,
		})
	return pairs

func _panel_color(panel_node: Panel) -> Color:
	var style: StyleBox = panel_node.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		return (style as StyleBoxFlat).bg_color
	return Color.WHITE

func _find_matching_panel(color: Color, candidates: Array[Panel]) -> Panel:
	for candidate in candidates:
		if _panel_color(candidate).is_equal_approx(color):
			return candidate
	return null

func _get_or_create_line(area: Area2D) -> Line2D:
	var existing: Node = area.get_node_or_null("Line2D")
	if existing is Line2D:
		return existing as Line2D
	var line := Line2D.new()
	area.add_child(line)
	return line

func _area_center(area: Area2D) -> Vector2:
	var collision: CollisionShape2D = area.get_child(0) as CollisionShape2D
	if collision:
		return area.position + collision.position
	return area.position

func _closest_area(point_panel: Panel, areas: Array[Area2D]) -> Area2D:
	var center: Vector2 = point_panel.position + point_panel.size / 2.0
	var best: Area2D = areas[0]
	var best_dist: float = center.distance_to(areas[0].position)
	for area in areas:
		var d: float = center.distance_to(area.position)
		if d < best_dist:
			best = area
			best_dist = d
	return best

func _area_radius(area: Area2D) -> float:
	var collision: CollisionShape2D = area.get_child(0) as CollisionShape2D
	if collision and collision.shape is CircleShape2D:
		return (collision.shape as CircleShape2D).radius
	return 10.0

func _process(_delta: float):
	if finished:
		return
	
	var local_mouse: Vector2 = $Panel.get_local_mouse_position()
	
	if dragging_index == -1:
		if Input.is_action_just_pressed("Click"):
			_try_start_drag(local_mouse)
		return
	
	var pair = _pairs[dragging_index]
	var line: Line2D = pair["line"]
	var anchor_pos: Vector2 = pair["left_area_pos"]
	line.set_point_position(1, local_mouse - anchor_pos)
	
	if not Input.is_action_pressed("Click"):
		_end_drag(local_mouse)

func _try_start_drag(local_mouse: Vector2):
	var index: int = _find_pair_at(local_mouse, true)
	if index != -1 and not _pairs[index]["connected"]:
		_start_drag(index)

func _start_drag(index: int):
	dragging_index = index
	print("[ConexionCables] empezando arrastre del par ", index)
	
	if first_input:
		first_input = false
		interacted.emit()

func _end_drag(release_pos: Vector2):
	var pair: Dictionary = _pairs[dragging_index]
	var line: Line2D = pair["line"]
	var anchor_pos: Vector2 = pair["left_area_pos"]
	var target_hit: Vector2 = pair["right_hit_pos"]
	var target_radius: float = pair["right_radius"]
	var line_origin: Vector2 = pair["line_origin"]
	var dropped_on_target: bool = release_pos.distance_to(target_hit) <= target_radius + 6.0
	
	if dropped_on_target:
		pair["connected"] = true
		line.set_point_position(1, target_hit - anchor_pos)
	else:
		line.set_point_position(1, line_origin)
	
	dragging_index = -1
	
	if dropped_on_target:
		_check_solved()

func _find_pair_at(local_pos: Vector2, left_side: bool) -> int:
	for i in _pairs.size():
		var pos: Vector2 = _pairs[i]["left_hit_pos"] if left_side else _pairs[i]["right_hit_pos"]
		var radius: float = _pairs[i]["left_radius"] if left_side else _pairs[i]["right_radius"]
		if local_pos.distance_to(pos) <= radius + 6.0:
			return i
	return -1

func _check_solved():
	for pair in _pairs:
		if not pair["connected"]:
			return
	finished = true
	set_process(false)
	solved.emit()

func _is_mouse_over(point: Panel) -> bool:
	return Rect2(Vector2.ZERO, point.size).has_point(point.get_local_mouse_position())
