extends CanvasLayer

@onready var animation: AnimationPlayer = %Animation

var lastSceneName : String

var sceneDirPath = "res://Scenes/"

func change_scene(from: Node, toSceneName: String):
	var full_path = sceneDirPath + toSceneName + ".tscn"
	
	lastSceneName = from.name
	
	animation.play("transition_out")
	
	await animation.animation_finished
	from.get_tree().call_deferred("change_scene_to_file", full_path)
	
	animation.play_backwards("transition_in")
