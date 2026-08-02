extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var coyote_timer: float = 0.0
var jump_buffer: float = 0.0
var start_position: Vector2

func _ready() -> void:
	SaveManager.load_game()
	global_position = Global.checkpoint_position
	start_position = global_position
	
func _physics_process(delta):
	# --- MEKANIK METRONOME (Order: Presisi Normal vs Disorder: Ngebut & Lompat Tinggi) ---
	var speed = 220.0 if Global.is_order_phase else 280.0
	var jump_power = 420.0 if Global.is_order_phase else 500.0

	up_direction = -Global.gravity_direction
	rotation = Vector2.DOWN.angle_to(Global.gravity_direction)
	if not is_on_floor():
		velocity += gravity * delta * Global.gravity_direction

	# --- 3 FITUR PEMAAFAN GERAKAN MODERN ---
	coyote_timer = 0.15 if is_on_floor() else coyote_timer - delta
	jump_buffer = 0.1 if Input.is_action_just_pressed("jump") else jump_buffer - delta

	if jump_buffer > 0 and coyote_timer > 0:
		velocity -= Global.gravity_direction * jump_power
		coyote_timer = 0.0; jump_buffer = 0.0 # Reset agar tidak lompat ganda
		$JumpSound.play() # Putar efek suara lompat

	if Input.is_action_just_released("jump") and velocity.dot(Global.gravity_direction) < 0:
		velocity *= 0.5

	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		$Sprite2D.play("Run")
		$Sprite2D.flip_h = direction < 0
	else:
		$Sprite2D.play("Idle")

	if Global.gravity_direction.x != 0:
		velocity.y = direction * speed
	else:
		velocity.x = direction * speed

	# Fitur DASH: HANYA Aktif di Fase Disorder! (Tekan X atau C di udara)
	if not Global.is_order_phase and (Input.is_key_pressed(KEY_X) or Input.is_key_pressed(KEY_C)) and not is_on_floor():
		velocity.x = (speed * 2.5) * (-1 if $Sprite2D.flip_h else 1)

	move_and_slide()

	# Kembali ke posisi awal jika jatuh melewati batas Y (jurang/void)
	if global_position.y > 400.0:
		global_position = start_position
		velocity = Vector2.ZERO
