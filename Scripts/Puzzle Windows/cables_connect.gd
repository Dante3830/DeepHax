class_name CablesConnect
extends PuzzleMinigame

class CablePair:
	var start: Panel
	var end: Panel
	var line: Line2D
	var connected = false
	
	func _init(start_point: Panel, end_point: Panel, cable: Line2D):
		start = start_point
		end = end_point
		line = cable

var variations = [$Variation1, $Variation2, $Variation3]
var pairs = []
var dragged = null
var used_variation = null

func _ready():
	set_process(false)
	
	used_variation = variations.pick_random()
	for variation in variations:
		variation.visible = variation == used_variation
	
	pairs = _build_pairs(used_variation)

func start():
	set_process(true)

func _process(_delta: float):
	if dragged == null:
		if Input.is_action_just_pressed("Click"):
			_grab_cable()
		return
	
	dragged.line.set_point_position(1, used_variation.get_local_mouse_position())
	
	if not Input.is_action_pressed("Click"):
		_drop_cable()

func _grab_cable():
	for pair in pairs:
		if not pair.connected and is_mouse_over(pair.start):
			dragged = pair
			if not interacted:
				interacted.emit()
			return

func _drop_cable():
	var pair = dragged
	dragged = null
	
	if is_mouse_over(pair.end):
		pair.connected = true
		pair.line.set_point_position(1, center(pair.end))
		_check_solved()
	else:
		pair.line.set_point_position(1, center(pair.start))

func _check_solved():
	if pairs.all(func(pair: CablePair): return pair.connected):
		set_process(false)
		solved.emit()

func _build_pairs(variation: Control) -> Array[CablePair]:
	var starts = []
	var ends = {}
	for child in variation.get_children():
		if child.name.begins_with("PointA"):
			starts.append(child)
		elif child.name.begins_with("PointB"):
			ends[panel_color(child)] = child
	
	var pairs = []
	for start in starts:
		var color = panel_color(start)
		if not ends.has(color):
			continue
		var line := create_line(variation, color, center(start))
		pairs.append(CablePair.new(start, ends[color], line))
	return pairs

func create_line(parent: Control, color: Color, origin: Vector2) -> Line2D:
	var line = Line2D.new()
	line.default_color = color
	line.add_point(origin)
	line.add_point(origin)
	parent.add_child(line)
	return line

func panel_color(point: Panel) -> Color:
	var style := point.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		return (style as StyleBoxFlat).bg_color
	return Color.WHITE

func center(point: Panel) -> Vector2:
	return point.position + point.size / 2.0

func is_mouse_over(point: Panel) -> bool:
	return Rect2(Vector2.ZERO, point.size).has_point(point.get_local_mouse_position())
