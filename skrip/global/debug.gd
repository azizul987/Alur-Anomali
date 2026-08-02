extends Node

var  dev_mode:=true
var allow_dev_mode:=OS.is_debug_build()

func _input(event: InputEvent) -> void:
	if not allow_dev_mode:
		return
	if event.is_action_pressed("toggle_dev_mode"):
		dev_mode=!dev_mode
		#print("DEV MODE IS ",dev_mode)

func is_active():
	return dev_mode and  allow_dev_mode
