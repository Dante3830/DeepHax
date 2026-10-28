extends Control

@onready var animationPlayer = $AnimationPlayer
@onready var items = [$Upgrades/Item1, $Upgrades/Item2, $Upgrades/Item3]

var objects = []

func _ready():
	# Esto fue solo para probar la tienda, che
	if get_tree().current_scene == self:
		GameManager.phase = 2
		GameManager.hackoins = 50
		GameManager.linesCombo = 3
	
	$Hackoins.visible = false
	$Combo.visible = false
	$StartHackingButton.visible = false
	for item in items:
		item.visible = false
	
	if GameManager.phase >= 2:
		var ids = Upgrades.ITEMS.keys()
		ids.shuffle()
		objects = ids.slice(0, items.size())
		for i in objects.size():
			fill_item(i)
	
	await show_percentage()
	await show_combo()
	update_shop()
	$Hackoins.visible = true
	$StartHackingButton.visible = true
	
	for i in objects.size():
		items[i].visible = true

func show_percentage():
	match GameManager.phase:
		1:
			$Percentage.text = "0% COMPLETADO"
			animationPlayer.play("phase_1")
		2:
			$Percentage.text = "25% COMPLETADO"
			animationPlayer.play("light_1_on")
			await animationPlayer.animation_finished
			animationPlayer.play("transition_1")
			await animationPlayer.animation_finished
			animationPlayer.play("phase_2")
		3:
			$Percentage.text = "50% COMPLETADO"
			animationPlayer.play("phase_3")
		4:
			$Percentage.text = "75% COMPLETADO"
			animationPlayer.play("phase_4")
		5:
			$Percentage.text = "100% COMPLETADO"

func show_combo():
	var combo = GameManager.linesCombo
	if combo < 2:
		GameManager.linesCombo = 1
		return
	
	var total = GameManager.hackoins * combo
	
	$Combo.visible = true
	$Combo.text = "x" + str(combo)
	$Hackoins.visible = true
	$Hackoins.text = "Hackoins conseguidas: " + str(GameManager.hackoins)
	
	await get_tree().create_timer(1.0).timeout
	
	GameManager.hackoins = total
	GameManager.linesCombo = 1
	
	$Combo.visible = false
	$Hackoins.text = "Hackoins conseguidas: " + str(GameManager.hackoins)

func fill_item(i: int):
	var id = objects[i]
	var data = Upgrades.ITEMS[id]
	items[i].get_node("Name").text = data["name"]
	var description = items[i].get_node("Description")
	description.text = data["description"]
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.offset_left = items[i].get_node("Name").offset_left
	description.offset_right = items[i].get_node("Name").offset_right
	items[i].get_node("Price").text = "%d hackoins" % data["price"]
	items[i].pressed.connect(buy.bind(id))

func buy(id: String):
	var cost = Upgrades.ITEMS[id]["price"]
	if Upgrades.has(id) or GameManager.hackoins < cost:
		return
	GameManager.hackoins -= cost
	Upgrades.bought.append(id)
	update_shop()

func update_shop():
	$Hackoins.text = "Hackoins conseguidas: " + str(GameManager.hackoins)
	for i in objects.size():
		var id = objects[i]
		var item = items[i]
		var bought = Upgrades.has(id)
		item.disabled = bought
		item.get_node("Bought").visible = bought
		item.get_node("Price").visible = !bought
		if GameManager.hackoins < Upgrades.ITEMS[id]["price"]:
			item.get_node("Price").add_theme_color_override("font_color", Color(1.0, 0.0, 0.0, 1.0))
		else:
			item.get_node("Price").remove_theme_color_override("font_color")

func on_start_hacking_button_pressed():
	GameManager.linesCombo = 0
	SceneManager.change_scene(self, "Phases/Phase2")
