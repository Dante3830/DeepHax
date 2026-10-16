class_name PuzzleMinigame
extends Control

signal interacted
signal finished(success: bool)

var _has_interacted = false
var _is_finished = false

func start():
	pass

func notify_interaction():
	if not _has_interacted:
		_has_interacted = true
		interacted.emit()

func finish(success: bool):
	if not _is_finished:
		_is_finished = true
		set_process(false)
		finished.emit(success)
