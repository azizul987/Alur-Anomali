extends CharacterBody2D

const SPEED = 200.0
const JUMP_POWER = 400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var coyote_timer: float = 0.0
var jump_buffer: float = 0.0
var start_position: Vector2

func _ready() -> void:
	SaveManager.load_game()
	global_position = Global.checkpoint_position
	start_position = global_position
	
func _physics_process(delta):
	up_direction = -Global.gravity_direction
	rotation = Vector2.DOWN.angle_to(Global.gravity_direction)
	if not is_on_floor():
		velocity += gravity * delta * Global.gravity_direction

	# --- 3 FITUR PEMAAFAN GERAKAN MODERN (Coyote Time, Jump Buffer, Variable Jump) ---
	coyote_timer = 0.15 if is_on_floor() else coyote_timer - delta
	jump_buffer = 0.1 if Input.is_action_just_pressed("jump") else jump_buffer - delta

	if jump_buffer > 0 and coyote_timer > 0:
		velocity -= Global.gravity_direction * JUMP_POWER
		coyote_timer = 0.0; jump_buffer = 0.0 # Reset agar tidak lompat ganda
		$JumpSound.play() # Putar efek suara lompat

	if Input.is_action_just_released("jump") and velocity.dot(Global.gravity_direction) < 0:
		velocity *= 0.5
	# ---------------------------------------------------------------------------------

	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		$Sprite2D.play("Run")
		$Sprite2D.flip_h = direction < 0
	else:
		$Sprite2D.play("Idle")

	# Gravitasi kiri atau kanan.
	if Global.gravity_direction.x != 0:
		velocity.y = direction * SPEED

	# Gravitasi atas atau bawah.
	else:
		velocity.x = direction * SPEED

	move_and_slide()

	# Kembali ke posisi awal jika jatuh melewati batas Y (jurang/void)
	if global_position.y > 400.0:
		global_position = start_position
		velocity = Vector2.ZERO
