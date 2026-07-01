extends Control

@onready var light_1 = $Lights/Light1
@onready var light_2 = $Lights/Light1
@onready var light_3 = $Lights/Light1
@onready var light_4 = $Lights/Light1

@onready var animation_player = $AnimationPlayer

func _set_light_on(light: Panel, on: bool) -> void:
	# Cambia solo el bg_color del StyleBoxFlat del panel, manteniendo el borde intacto
	var style = light.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		style.bg_color = Color(0.0, 1.0, 0.0, 1.0) if on else Color(0, 0, 0, 1)
