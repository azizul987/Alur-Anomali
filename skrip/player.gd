extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var coyote_timer: float = 0.0
var jump_buffer: float = 0.0
var jump_count: int = 0
var air_dash_used: bool = false
var dash_timer: float = 0.0
var start_position: Vector2

func _ready() -> void:
	SaveManager.load_game()
	global_position = Global.checkpoint_position
	start_position = global_position
	
func _physics_process(delta):
	# --- FITUR ADMIN / DEV FLY MODE (NO-CLIP / BEBAS TERBANG & TEMBUS KETIKA TEST LEVEL) ---
	if Debug.is_active() and Debug.fly_mode:
		var fly_dir = Vector2.ZERO
		if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A): fly_dir.x -= 1
		if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D): fly_dir.x += 1
		if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W): fly_dir.y -= 1
		if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S): fly_dir.y += 1
		
		var fly_speed = 450.0 * (2.5 if (Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_X)) else 1.0)
		position += fly_dir.normalized() * fly_speed * delta
		velocity = Vector2.ZERO
		return # Abaikan gravitasi & tabrakan demi meluncur bebas mengelilingi level!

	if is_on_floor():
		jump_count = 0
		air_dash_used = false
		dash_timer = 0.0

	# --- MEKANIK METRONOME (Order: Normal vs Disorder: Lompat 1.1x & Laju 1.8x) ---
	var speed = 205.0 * (1.0 if Global.is_order_phase else 1.8) # Laju 1.8x di Disorder
	var jump_power = 270.0 * (1.0 if Global.is_order_phase else 1.1) # Kekuatan lompat dibagi 2 demi Double Jump!

	up_direction = -Global.gravity_direction
	rotation = Vector2.DOWN.angle_to(Global.gravity_direction)
	if not is_on_floor():
		velocity += gravity * delta * Global.gravity_direction

	# --- FITUR DOUBLE JUMP & PEMAAFAN GERAKAN MODERN ---
	coyote_timer = 0.15 if is_on_floor() else coyote_timer - delta
	jump_buffer = 0.1 if Input.is_action_just_pressed("jump") else jump_buffer - delta

	if jump_buffer > 0 and (coyote_timer > 0 or jump_count < 2):
		velocity.y = -jump_power
		jump_count = 1 if (coyote_timer > 0) else 2
		coyote_timer = 0.0; jump_buffer = 0.0 # Reset agar tidak lompat ganda berlebih
		$JumpSound.play() # Putar efek suara lompat

	if Input.is_action_just_released("jump") and velocity.dot(Global.gravity_direction) < 0:
		velocity *= 0.5

	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		$Sprite2D.play("Run")
		$Sprite2D.flip_h = direction < 0
	else:
		$Sprite2D.play("Idle")

	var on_ice = false
	var conveyor_push = 0.0
	for i in get_slide_collision_count():
		var col = get_slide_collision(i).get_collider()
		if col:
			if "is_ice" in col and col.is_ice: on_ice = true
			if "conveyor_speed" in col and col.conveyor_speed != 0:
				conveyor_push = col.conveyor_speed * (1.2 if Global.is_order_phase else -2.5)
			if "has_been_touched" in col: col.has_been_touched = true

	var dash_pressed = Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_X) or Input.is_key_pressed(KEY_C)
	if dash_pressed and jump_count >= 2 and not is_on_floor() and not air_dash_used:
		air_dash_used = true # Kunci agar tidak bisa double dash beruntun di udara!
		dash_timer = 0.25 # Durasi melesat cepat selama 0.25 detik

	if dash_timer > 0: dash_timer -= delta
	# Di atas lantai bisa lari cepat (sprint/dash) bebas, sedangkan di udara wajib mematuhi timer air dash!
	var is_dash = (dash_pressed and is_on_floor()) or (dash_timer > 0)
	var mult = 1.0
	if is_dash: mult = 2.0 if Global.is_order_phase else 2.6 # Kecepatan melaju dash darat maupun udara!

	if Global.gravity_direction.x != 0:
		velocity.y = direction * speed * mult + conveyor_push
	elif not Global.is_order_phase and on_ice:
		velocity.x = move_toward(velocity.x, direction * (speed * 1.8) + conveyor_push, 4.0)
	else:
		velocity.x = direction * speed * mult + conveyor_push

	# Batasi laju horizontal saat di udara HANYA JIKA TIDAK sedang menekan tombol Dash
	if not is_on_floor() and not is_dash and Global.gravity_direction.y != 0:
		var max_air = 235.0 if Global.is_order_phase else 265.0
		velocity.x = clamp(velocity.x, -max_air, max_air)

	move_and_slide()

	# Kembali ke posisi awal jika jatuh melewati batas Y (jurang/void)
	if global_position.y > 400.0:
		global_position = start_position
		velocity = Vector2.ZERO
