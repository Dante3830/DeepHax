extends Control

@onready var light_1 = $Lights/Light1
@onready var light_2 = $Lights/Light1
@onready var light_3 = $Lights/Light1
@onready var light_4 = $Lights/Light1
@onready var percentage = $Percentage.text
@onready var hackoins_text = $Hackoins.text

@onready var animation_player = $AnimationPlayer

func _process(delta: float) -> void:
	show_percentage()

func show_percentage():
	match GameManager.phase:
		1: 
			$Percentage.text = "0% COMPLETADO"
			animation_player.play("phase_1")
		2: 
			$Percentage.text = "25% COMPLETADO"
			animation_player.play("phase_2")
		3: 
			$Percentage.text = "50% COMPLETADO"
			animation_player.play("phase_3")
		4: 
			$Percentage.text = "75% COMPLETADO"
			animation_player.play("phase_4")
		5: $Percentage.text = "100% COMPLETADO"

func show_hackoins():
	hackoins_text.text = str(GameManager.hackoins)

func _set_light_on(light: Panel, on: bool) -> void:
	# Cambia solo el bg_color del StyleBoxFlat del panel, manteniendo el borde intacto
	var style = light.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		style.bg_color = Color(0.0, 1.0, 0.0, 1.0) if on else Color(0, 0, 0, 1)

func _on_start_hacking_button_pressed() -> void:
	pass # Replace with function body.
