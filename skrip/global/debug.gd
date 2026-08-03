extends Node

var dev_mode := true
var allow_dev_mode := true # Selalu izinkan selagi masa Game Jam & debug
var fly_mode := false

func _input(event: InputEvent) -> void:
	if not allow_dev_mode:
		return
	if event.is_action_pressed("toggle_dev_mode") or (event is InputEventKey and event.physical_keycode == KEY_TAB and event.pressed and not event.echo):
		dev_mode = !dev_mode

	# Custom input Admin untuk memicu Mode Terbang (Fly/No-Clip Admin Mode) - Tekan tombol F (atau F1)
	if dev_mode and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F or event.physical_keycode == KEY_F1:
			fly_mode = !fly_mode
			# print("ADMIN FLY MODE IS ", fly_mode)

func is_active():
	return dev_mode and allow_dev_mode
