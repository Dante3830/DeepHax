extends Control

@onready var animationPlayer = $AnimationPlayer
@onready var items = [$Upgrader/Item1, $Upgrader/Item2, $Upgrader/Item3]

var offers = []

func _ready():
	$Hackoins.visible = false
	$StartHackingButton.visible = false
	for item in items:
		item.visible = false
	
	if GameManager.phase >= 2:
		var ids = Upgrader.ITEMS.keys()
		ids.shuffle()
		offers = ids.slice(0, items.size())
		for i in offers.size():
			fill_item(i)
	
	await show_percentage()
	
	refresh()
	$Hackoins.visible = true
	$StartHackingButton.visible = true
	for i in offers.size():
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

func fill_item(i: int):
	var id = offers[i]
	var data = Upgrader.ITEMS[id]
	items[i].get_node("Name").text = data["name"]
	var description = items[i].get_node("Description")
	description.text = data["description"]
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.offset_left = items[i].get_node("Name").offset_left
	description.offset_right = items[i].get_node("Name").offset_right
	items[i].get_node("Price").text = "%d hackoins" % data["cost"]
	items[i].pressed.connect(buy.bind(id))

func buy(id: String):
	var cost = Upgrader.ITEMS[id]["cost"]
	if Upgrader.has(id) or GameManager.hackoins < cost:
		return
	GameManager.hackoins -= cost
	Upgrader.bought.append(id)
	refresh()

func refresh():
	$Hackoins.text = "Hackoins: %03d" % GameManager.hackoins
	for i in offers.size():
		var id = offers[i]
		var item = items[i]
		var bought = Upgrader.has(id)
		item.get_node("Bought").visible = bought
		item.get_node("Price").visible = !bought
		if GameManager.hackoins < Upgrader.ITEMS[id]["cost"]:
			item.get_node("Price").add_theme_color_override("font_color", Color(1, 0.35, 0.35))
		else:
			item.get_node("Price").remove_theme_color_override("font_color")

func on_start_hacking_button_pressed():
	SceneManage.change_scene(self, "Phase%d" % GameManager.phase)
