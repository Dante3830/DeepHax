extends Control

@onready var label = $Label2

func _ready():
	label.visible_ratio = 0.0
	$RejectButton.visible = false

func _process(delta: float):
	label.visible_ratio += 1.0 * delta
	
	if label.visible_ratio >= 1.0:
		$RejectButton.visible = true
	
	if Input.is_action_just_pressed("Enter"):
		SceneManager.change_scene(self, "Phases/Phase1")

func on_reject_button_pressed():
	get_tree().quit()
