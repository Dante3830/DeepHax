extends Control

@onready var light1 = $Lights/Light1
@onready var light2 = $Lights/Light2
@onready var light3 = $Lights/Light3
@onready var light4 = $Lights/Light4
@onready var percentage = $Percentage.text
@onready var hackoins_text = $Hackoins.text
@onready var animation_player = $AnimationPlayer

func _ready():
	$Hackoins.visible = false
	$StartHackingButton.visible = false

func _process(delta: float):
	await show_percentage()
	show_hackoins()
	$StartHackingButton.visible = true

func show_percentage():
	match GameManager.phase:
		1: 
			$Percentage.text = "0% COMPLETADO"
			animation_player.play("phase_1")
		2: 
			$Percentage.text = "25% COMPLETADO"
			await animation_player.play("light_1_on")
			await animation_player.play("transition_1")
			animation_player.play("phase_2")
		3: 
			$Percentage.text = "50% COMPLETADO"
			animation_player.play("phase_3")
		4: 
			$Percentage.text = "75% COMPLETADO"
			animation_player.play("phase_4")
		5: $Percentage.text = "100% COMPLETADO"

func show_hackoins():
	$Hackoins.visible = false
	hackoins_text.text = str(GameManager.hackoins)

func _on_start_hacking_button_pressed():
	SceneManage.change_scene(self, "Phase2")
