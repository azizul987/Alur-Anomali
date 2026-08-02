extends Node

var current_level: int = 1
var checkpoint_position: Vector2 = Vector2.ZERO
var current_rule: int = 0
var gravity_direction: Vector2 = Vector2.UP
var death_count: int = 0

# --- PROTOTYPE MEKANIK METRONOME (KONTROL KEYBOARD) ---
var is_order_phase: bool = true # True = Order (Tick), False = Disorder (Tock)

func toggle_phase() -> void:
	is_order_phase = not is_order_phase
	print("FASE METRONOME: ", "ORDER (Tick) 🟢" if is_order_phase else "DISORDER (Tock) 🔴")
	if is_order_phase:
		gravity_direction = Vector2.DOWN # Gravitasi stabil ke bawah saat Order
# ----------------------------------------------------
			
func _input(event: InputEvent) -> void:
	# Tekan Tombol E atau M atau TAB untuk ganti mode Order <-> Disorder
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_E, KEY_M, KEY_TAB]:
			toggle_phase()

	if event.is_action_pressed("change_grav") and Debug.is_active():
		Global.gravity_direction = Global.gravity_direction.rotated(PI / 2.0).round()
	if event.is_action_pressed("reset_save"):
		print("wasasa")
		SaveManager.delete_current_save()
