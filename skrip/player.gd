extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var coyote_timer: float = 0.0
var jump_buffer: float = 0.0
var jump_count: int = 0
var air_dash_used: bool = false
var dash_timer: float = 0.0
var start_position: Vector2
var run_particles: CPUParticles2D
var was_on_floor: bool = false

func _ready() -> void:
	SaveManager.load_game()
	if Global.checkpoint_position != Vector2.ZERO:
		global_position = Global.checkpoint_position
	else:
		Global.checkpoint_position = global_position
	start_position = global_position
	
	# Setup animasi Jump dan Fall secara dinamis (tanpa menimpa file .tscn!)
	if has_node("Sprite2D") and $Sprite2D.sprite_frames:
		var frames = $Sprite2D.sprite_frames
		if not frames.has_animation("Jump"):
			frames.add_animation("Jump")
			var jump_tex = load("res://asset/Pixel Adventure 1/Main Characters/Ninja Frog/Jump (32x32).png")
			if jump_tex:
				var atlas_j = AtlasTexture.new()
				atlas_j.atlas = jump_tex
				atlas_j.region = Rect2(0, 0, 32, 32)
				frames.add_frame("Jump", atlas_j)
				frames.set_animation_loop("Jump", false)
				
		if not frames.has_animation("Fall"):
			frames.add_animation("Fall")
			var fall_tex = load("res://asset/Pixel Adventure 1/Main Characters/Ninja Frog/Fall (32x32).png")
			if fall_tex:
				var atlas_f = AtlasTexture.new()
				atlas_f.atlas = fall_tex
				atlas_f.region = Rect2(0, 0, 32, 32)
				frames.add_frame("Fall", atlas_f)
				frames.set_animation_loop("Fall", false)
	
	# Setup efek partikel debu lari di kaki pemain
	run_particles = CPUParticles2D.new()
	run_particles.position = Vector2(0, 13) # Pas di telapak kaki pemain
	run_particles.amount = 8
	run_particles.lifetime = 0.25
	run_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	run_particles.emission_rect_extents = Vector2(4, 2)
	run_particles.direction = Vector2(-1, -0.5)
	run_particles.gravity = Vector2(0, -25) # Debu mengepul naik sedikit ke atas
	run_particles.initial_velocity_min = 15.0
	run_particles.initial_velocity_max = 30.0
	run_particles.scale_amount_min = 2.0
	run_particles.scale_amount_max = 4.0
	
	var ramp = Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.75)) # Putih terang
	ramp.set_color(1, Color(1, 1, 1, 0.0))  # Pudar transparan
	run_particles.color_ramp = ramp
	run_particles.emitting = false
	add_child(run_particles)
	
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
		var is_double = (coyote_timer <= 0 and jump_count >= 1)
		jump_count = 1 if (coyote_timer > 0) else 2
		coyote_timer = 0.0; jump_buffer = 0.0 # Reset agar tidak lompat ganda berlebih
		$JumpSound.play() # Putar efek suara lompat
		spawn_jump_dust(is_double, false)

	if Input.is_action_just_released("jump") and velocity.dot(Global.gravity_direction) < 0:
		velocity *= 0.5

	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		$Sprite2D.flip_h = direction < 0
		if run_particles:
			run_particles.direction = Vector2(-direction, -0.4)
			
	if not is_on_floor():
		# Saat melayang di udara: gunakan dot product agar animasi akurat di segala arah gravitasi anomali!
		if velocity.dot(Global.gravity_direction) < 0:
			$Sprite2D.play("Jump")
		else:
			$Sprite2D.play("Fall")
	elif direction != 0:
		$Sprite2D.play("Run")
	else:
		$Sprite2D.play("Idle")
		
	if run_particles:
		run_particles.emitting = is_on_floor() and abs(velocity.x) > 10.0

	var on_ice = false
	var conveyor_push = 0.0
	for i in get_slide_collision_count():
		var col = get_slide_collision(i).get_collider()
		if col:
			if "is_ice" in col and col.is_ice: on_ice = true
			if "conveyor_speed" in col and col.conveyor_speed != 0:
				var spd = abs(col.conveyor_speed)
				if "is_treadmill_normal" in col and col.is_treadmill_normal:
					conveyor_push = spd if Global.is_order_phase else -spd
				elif "is_treadmill_disorder" in col and col.is_treadmill_disorder:
					conveyor_push = spd if not Global.is_order_phase else -spd
				else:
					conveyor_push = col.conveyor_speed * (1.2 if Global.is_order_phase else -2.5)
			if col.has_method("trigger_touch"):
				col.trigger_touch(self)
			elif "has_been_touched" in col:
				col.has_been_touched = true

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

	# Efek kejut debu saat mendarat di atas tanah setelah melayang dari udara!
	if is_on_floor() and not was_on_floor:
		spawn_jump_dust(false, true)
	was_on_floor = is_on_floor()
			
	if global_position.y > 400.0:
		mati()
		
func mati():
	global_position = start_position
	velocity = Vector2.ZERO
	Global.reset_trap.emit()
	print("Anda Mati")

# --- EFEK DEBU KAKI (PARTICULATE DUST VIRTUAL) ---
func spawn_jump_dust(is_double: bool = false, is_landing: bool = false) -> void:
	var dust = CPUParticles2D.new()
	get_parent().add_child(dust)
	dust.global_position = global_position + Vector2(0, 13) # Posisi telapak kaki
	dust.emitting = true
	dust.one_shot = true
	dust.explosiveness = 1.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	
	var ramp = Gradient.new()
	
	if is_double:
		# Efek Double Jump di udara: Ledakan cincin debu berputar ke segala arah!
		dust.amount = 24
		dust.lifetime = 0.35
		dust.emission_rect_extents = Vector2(8, 3)
		dust.spread = 180.0
		dust.initial_velocity_min = 40.0
		dust.initial_velocity_max = 85.0
		dust.scale_amount_min = 3.0
		dust.scale_amount_max = 6.0
		dust.gravity = Vector2(0, 45)
		# Sentuhan warna cerah sesuai mode atmosfer (Order vs Disorder)
		var start_col = Color(0.9, 0.98, 1.0, 0.95) if Global.is_order_phase else Color(1.0, 0.7, 0.8, 0.95)
		ramp.set_color(0, start_col)
		ramp.set_color(1, Color(start_col.r, start_col.g, start_col.b, 0.0))
	elif is_landing:
		# Efek Mendarat: Hembusan debu mendatar ke kanan & kiri tatak lantai
		dust.amount = 14
		dust.lifetime = 0.25
		dust.emission_rect_extents = Vector2(10, 2)
		dust.direction = Vector2(0, -1) # Sedikit terdorong ke atas tatak lantai
		dust.spread = 75.0
		dust.initial_velocity_min = 25.0
		dust.initial_velocity_max = 55.0
		dust.scale_amount_min = 2.0
		dust.scale_amount_max = 5.0
		dust.gravity = Vector2(0, -15)
		ramp.set_color(0, Color(1, 1, 1, 0.8))
		ramp.set_color(1, Color(1, 1, 1, 0.0))
	else:
		# Efek Lompat Dasar: Tolakan debu ke bawah lantai
		dust.amount = 12
		dust.lifetime = 0.3
		dust.emission_rect_extents = Vector2(6, 2)
		dust.direction = Vector2(0, 1) # Menolak ke bawah lantai
		dust.spread = 60.0
		dust.initial_velocity_min = 30.0
		dust.initial_velocity_max = 65.0
		dust.scale_amount_min = 2.5
		dust.scale_amount_max = 5.0
		dust.gravity = Vector2(0, 20)
		ramp.set_color(0, Color(1, 1, 1, 0.85))
		ramp.set_color(1, Color(1, 1, 1, 0.0))
		
	dust.color_ramp = ramp
	dust.finished.connect(dust.queue_free) # Bersihkan otomatis setelah meledak!
