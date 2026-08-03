extends AnimatableBody2D

enum TipePlatform {
	NORMAL = 0,
	PENDULUM = 1,
	SHADOW_DISORDER = 2,
	ICE_SURFACE = 3,
	MEMORY_REWIND = 4,
	FALL_ON_TOUCH = 5,
	DISAPPEAR_ON_TOUCH = 6,
	MOVE_ON_TOUCH = 7,
	SHIFT_ON_MODE = 8
}

@export_group("Dropdown Pilihan Tipe Platform")
## Pilih tipe platform menggunakan menu Dropdown murni di bawah ini:
@export var tipe_dropdown: TipePlatform = TipePlatform.NORMAL

@export_group("Pengaturan Fisika & Parameter")
@export var one_way: bool = true
@export var move_offset: Vector2 = Vector2.ZERO # Rute saat ORDER (Stabil, misal horizontal)
@export var disorder_offset: Vector2 = Vector2.ZERO # Rute saat DISORDER (Kacau/Melayang atas)
@export var move_speed: float = 2.0 # Kecepatan ayunan / pergeseran
@export var bounce_power: float = 0.0 # Isi misal 600.0 untuk jadi trampolin
@export var orbit_radius: float = 0.0 # Berputar 360 derajat mengitari titik awal
@export var conveyor_speed: float = 0.0 # Ban berjalan / angin pendorong

@export_group("Opsi Manual (Checklist Alternatif)")
@export var disappear_on_touch: bool = false
@export var is_pendulum: bool = false
@export var shadow_on_disorder: bool = false
@export var is_ice: bool = false
@export var is_memory_rewind: bool = false
@export var fall_on_touch: bool = false
@export var move_on_touch: bool = false
@export var shift_on_mode: bool = false

var origin_pos: Vector2
var history: Array[Vector2] = []
var cur_angle: float = 0.0
var is_falling: bool = false
var has_been_touched: bool = false
var move_timer: float = 0.0

func _ready() -> void:
	# Sinkronisasi dari menu Dropdown murni ke logika sistem:
	match tipe_dropdown:
		TipePlatform.PENDULUM: is_pendulum = true
		TipePlatform.SHADOW_DISORDER: shadow_on_disorder = true
		TipePlatform.ICE_SURFACE: is_ice = true
		TipePlatform.MEMORY_REWIND: is_memory_rewind = true
		TipePlatform.FALL_ON_TOUCH: fall_on_touch = true
		TipePlatform.DISAPPEAR_ON_TOUCH: disappear_on_touch = true
		TipePlatform.MOVE_ON_TOUCH: move_on_touch = true
		TipePlatform.SHIFT_ON_MODE: shift_on_mode = true

	origin_pos = position
	if has_node("CollisionShape2D"):
		$CollisionShape2D.one_way_collision = one_way
	if has_node("Area2D") and not $Area2D.body_entered.is_connected(_on_area_2d_body_entered):
		$Area2D.body_entered.connect(_on_area_2d_body_entered)

func _physics_process(_delta: float) -> void:
	# 1. Mekanik Pendulum Platform (Ayunan jam)
	if is_pendulum:
		rotation = sin(Time.get_ticks_msec() * 0.001 * (2.0 if Global.is_order_phase else 7.0)) * 0.6

	# 2. Mekanik Shadow Platform (Nyata saat Order, Ilusi/Tembus saat Disorder)
	if shadow_on_disorder:
		modulate.a = 1.0 if Global.is_order_phase else 0.25
		if has_node("CollisionShape2D"):
			$CollisionShape2D.disabled = not Global.is_order_phase

	# 3. Mekanik Orbit Platform (Berputar mulus dengan akumulasi sudut)
	if orbit_radius > 0:
		cur_angle += _delta * (1.5 if Global.is_order_phase else -5.0) # Disorder berputar terbalik kencang!
		position = origin_pos + Vector2(cos(cur_angle), sin(cur_angle)) * orbit_radius

	# 4. Mekanik Falling Platform (Jatuh saat diinjak)
	if is_falling:
		position.y += _delta * (120.0 if Global.is_order_phase else 380.0)
		if position.y > origin_pos.y + 400.0: is_falling = false; position = origin_pos

	# 5. Mekanik Memory / Time-Reversal Platform (Rewind rute mundur saat Order)
	if is_memory_rewind and not Global.is_order_phase:
		history.append(position)
		if history.size() > 300: history.pop_front()
	elif is_memory_rewind and history.size() > 0:
		position = history.pop_back(); return # Hentikan gerakan biasa demi rewind mundur!

	# 6. Mekanik Shift Pada Pergantian Mode (Diam di Posisi A saat Order, Bergeser tegap ke Posisi B saat Disorder)
	if shift_on_mode:
		var target_pos = origin_pos + (move_offset if Global.is_order_phase else disorder_offset)
		position = position.lerp(target_pos, 0.08 * move_speed)
	# 7. Mekanik Moving Platform Metronome: Bisa melayang langsung atau menunggu diinjak dulu (move_on_touch)
	elif move_offset != Vector2.ZERO or disorder_offset != Vector2.ZERO:
		if not move_on_touch or has_been_touched:
			move_timer += _delta * move_speed * 2.0
			var target_offset = move_offset if Global.is_order_phase else disorder_offset
			var target = origin_pos + target_offset * sin(move_timer)
			position = position.lerp(target, 0.1)

# Hubungkan sinyal "body_entered" dari node Area2D di platform ke fungsi ini
func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return

	if move_on_touch:
		has_been_touched = true

	# Efek Jatuh namun Garansi Tetap Bisa Lompat
	if fall_on_touch:
		is_falling = true
		if "coyote_timer" in body: body.coyote_timer = 0.5 # Waktu toleransi khusus agar bisa lompat!

	# Efek Trampolin / Lompat Tinggi
	if bounce_power > 0:
		body.velocity = -Global.gravity_direction * bounce_power

	# Efek Hancur / Lenyap Sementara (lalu muncul lagi pas 3 detik)
	if disappear_on_touch:
		await get_tree().create_timer(0.4).timeout # Jeda getar/tunggu sebelum jatuh
		hide()
		$CollisionShape2D.set_deferred("disabled", true)
		await get_tree().create_timer(3.0).timeout # Jeda waktu sebelum platform muncul lagi
		show()
		$CollisionShape2D.set_deferred("disabled", false)
