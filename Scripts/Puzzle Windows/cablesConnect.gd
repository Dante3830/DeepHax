class_name CablesConnect
extends PuzzleMinigame

class CablePair:
	var start: Panel
	var end: Panel
	var line: Line2D
	var connected = false
	
	func _init(startPoint: Panel, endPoint: Panel, cable: Line2D):
		start = startPoint
		end = endPoint
		line = cable

var pairs: Array[CablePair] = []
var cableDragged: CablePair = null
var usedVariation: Control = null

func _ready():
	set_process(false)
	
	var variations = [$Variation1, $Variation2, $Variation3]
	usedVariation = variations.pick_random()
	for variation in variations:
		variation.visible = variation == usedVariation
	
	pairs = set_pairs(usedVariation)

func start():
	set_process(true)

func _process(_delta: float):
	if cableDragged == null:
		if Input.is_action_just_pressed("Click"):
			start_cable()
		return
	
	cableDragged.line.set_point_position(1, usedVariation.get_local_mouse_position())
	
	if not Input.is_action_pressed("Click"):
		end_cable()

func start_cable():
	for pair in pairs:
		if !pair.connected and is_cursor_over(pair.start):
			cableDragged = pair
			notify_interaction()
			return

func end_cable():
	var pair = cableDragged
	cableDragged = null
	
	if is_cursor_over(pair.end):
		pair.connected = true
		pair.line.set_point_position(1, calculate_center(pair.end))
		all_cables_connected()
	else:
		pair.line.set_point_position(1, calculate_center(pair.start))

func all_cables_connected():
	if pairs.all(func(pair: CablePair): return pair.connected):
		finish(true)

func set_pairs(variation: Control) -> Array[CablePair]:
	var starts = []
	var ends = {}
	for child in variation.get_children():
		if child.name.begins_with("PointA"):
			starts.append(child)
		elif child.name.begins_with("PointB"):
			ends[get_panel_color(child)] = child
	
	var built: Array[CablePair] = []
	for i in starts:
		var color = get_panel_color(i)
		if not ends.has(color):
			continue
		var line := create_line(variation, color, calculate_center(i))
		built.append(CablePair.new(i, ends[color], line))
	return built

func create_line(parent: Control, color: Color, origin: Vector2) -> Line2D:
	var line = Line2D.new()
	line.default_color = color
	line.add_point(origin)
	line.add_point(origin)
	parent.add_child(line)
	return line

func get_panel_color(point: Panel) -> Color:
	var style = point.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		return (style as StyleBoxFlat).bg_color
	return Color.WHITE

func calculate_center(point: Panel) -> Vector2:
	return point.position + point.size / 2.0

func is_cursor_over(point: Panel) -> bool:
	return Rect2(Vector2.ZERO, point.size).has_point(point.get_local_mouse_position())
