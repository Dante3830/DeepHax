extends Control

@onready var animationPlayer = $AnimationPlayer
@onready var items = [$Upgrades/Item1, $Upgrades/Item2, $Upgrades/Item3]

var offers = []

func _ready():
	$Hackoins.visible = false
	$StartHackingButton.visible = false
	for item in items:
		item.visible = false
	
	if GameManager.phase >= 2:
		var ids = Upgrader.CATALOG.keys()
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
	var data = Upgrader.CATALOG[id]
	items[i].get_node("NameLabel").text = data["name"]
	items[i].get_node("DescriptionLabel").text = data["description"]
	items[i].get_node("CostLabel").text = "%d hackoins" % data["cost"]
	items[i].get_node("BuyButton").pressed.connect(buy.bind(id))

func buy(id: String):
	GameManager.hackoins -= Upgrader.CATALOG[id]["cost"]
	Upgrader.bought.append(id)
	refresh()

func refresh():
	$Hackoins.text = "Hackoins: %03d" % GameManager.hackoins
	for i in offers.size():
		var id = offers[i]
		var button = items[i].get_node("BuyButton")
		if Upgrader.has(id):
			button.text = "COMPRADO"
			button.disabled = true
		else:
			button.text = "COMPRAR"
			button.disabled = GameManager.hackoins < Upgrader.ITEMS[id]["cost"]

func on_start_hacking_button_pressed() -> void:
	SceneManage.change_scene(self, "Phase%d" % GameManager.phase)
