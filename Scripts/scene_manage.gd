extends CanvasLayer

@onready var animation: AnimationPlayer = %Animation

var last_scene_name : String

var scene_dir_path = "res://Scenes/"

func change_scene(from: Node, to_scene_name: String):
	var full_path = scene_dir_path + to_scene_name + ".tscn"
	
	last_scene_name = from.name
	
	animation.play("transition_out")
	
	await animation.animation_finished
	from.get_tree().call_deferred("change_scene_to_file", full_path)
	
	animation.play_backwards("transition_in")
