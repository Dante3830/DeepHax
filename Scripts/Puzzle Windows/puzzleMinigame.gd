class_name PuzzleMinigame
extends Control

signal interacted
signal finished(success: bool)

var hasInteracted = false
var isFinished = false

func start():
	pass

func notify_interaction():
	if !hasInteracted:
		hasInteracted = true
		interacted.emit()

func finish(success: bool):
	if !isFinished:
		isFinished = true
		set_process(false)
		finished.emit(success)
