class_name ConexionCables
extends PuzzleMinigame

# Microjuego "Conexión de cables": el jugador arrastra desde un punto de la
# izquierda (PointA#) hasta su correspondiente a la derecha (PointB#, MISMO
# COLOR, no necesariamente el mismo renglón) para "cablearlo". Se elige al
# azar una de las 3 variaciones (2, 3 o 4 cables) como nivel de dificultad.
# Conectar mal no penaliza: el cable vuelve a su anclaje y se reintenta.
#
# Cada Area2D del lado izquierdo ya trae su propio Line2D como hijo, con su
# color ya configurado a mano en el editor. El punto 0 del Line2D arranca en
# el centro REAL del CollisionShape2D (que puede estar corrido unos pixeles
# del origen del Area2D), no en (0,0) a secas.

# Dejá en -1 para elegir variación al azar. 0/1/2 fuerza Variation1/2/3.
@export var forced_variation_index: int = -1

@onready var panel: Panel = $Panel
@onready var variations: Array[Control] = [$Variation1, $Variation2, $Variation3]

# Cada entrada: { line, line_origin, left_area_pos, left_hit_pos, left_radius,
# right_hit_pos, right_radius, connected }
var _pairs: Array[Dictionary] = []

var _active_variation: Control = null
var _dragging_index: int = -1
var _first_input: bool = true
var _finished: bool = false


func _ready() -> void:
	set_process(false)

	var variation_index: int = forced_variation_index
	if variation_index < 0 or variation_index >= variations.size():
		variation_index = randi() % variations.size()

	_active_variation = variations[variation_index]
	for variation in variations:
		variation.visible = (variation == _active_variation)

	_pairs = _build_pairs(_active_variation)
	panel.gui_input.connect(_on_panel_gui_input)

	print("[ConexionCables] variación activa: ", variation_index, " | pares armados: ", _pairs.size())


func _build_pairs(variation: Control) -> Array[Dictionary]:
	var left_panels: Array[Panel] = []
	var right_panels: Array[Panel] = []
	var areas: Array[Area2D] = []

	for child in variation.get_children():
		if child is Panel:
			# Por default un Panel tiene mouse_filter = Stop y se come el
			# click él solo, sin dejarlo pasar a nuestro Panel de fondo.
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
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


# Centro real del CollisionShape2D (su propia posición local sumada a la del
# Area2D que lo contiene), en vez de asumir que coincide con el origen del
# Area2D.
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


func _on_panel_gui_input(event: InputEvent) -> void:
	if _finished or _dragging_index != -1:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var index: int = _find_pair_at(event.position, true)
		print("[ConexionCables] click en ", event.position, " -> par detectado: ", index)
		if index != -1 and not _pairs[index]["connected"]:
			_start_drag(index)


func _start_drag(index: int) -> void:
	_dragging_index = index
	set_process(true)
	print("[ConexionCables] empezando arrastre del par ", index)

	if _first_input:
		_first_input = false
		interacted.emit()


func _process(_delta: float) -> void:
	if _dragging_index == -1:
		set_process(false)
		return

	var pair: Dictionary = _pairs[_dragging_index]
	var line: Line2D = pair["line"]
	var anchor_pos: Vector2 = pair["left_area_pos"]
	var local_mouse: Vector2 = panel.get_local_mouse_position()

	line.set_point_position(1, local_mouse - anchor_pos)

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_end_drag(local_mouse)


func _end_drag(release_pos: Vector2) -> void:
	var pair: Dictionary = _pairs[_dragging_index]
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

	_dragging_index = -1
	set_process(false)

	if dropped_on_target:
		_check_solved()


func _find_pair_at(local_pos: Vector2, left_side: bool) -> int:
	for i in _pairs.size():
		var pos: Vector2 = _pairs[i]["left_hit_pos"] if left_side else _pairs[i]["right_hit_pos"]
		var radius: float = _pairs[i]["left_radius"] if left_side else _pairs[i]["right_radius"]
		if local_pos.distance_to(pos) <= radius + 6.0:
			return i
	return -1


func _check_solved() -> void:
	for pair in _pairs:
		if not pair["connected"]:
			return
	_finished = true
	solved.emit()
