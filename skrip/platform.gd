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
	SHIFT_ON_MODE = 8,
	SHADOW_ORDER = 9,
	TREADMILL_NORMAL = 10,
	TREADMILL_DISORDER = 11
}

@export_group("Dropdown Pilihan Tipe Platform")
## Pilih tipe platform menggunakan menu Dropdown murni di bawah ini:
@export var tipe_dropdown: TipePlatform = TipePlatform.NORMAL

enum WarnaPlatform {
	HIJAU = 0,
	COKELAT = 1,
	KUNING = 2,
	BIRU = 3
}

@export_group("Tampilan & Visual")
## Pilih warna visual platform dari spritesheet:
@export var warna_dropdown: WarnaPlatform = WarnaPlatform.HIJAU

@export_group("Target Rute Mudah (Marker / Tile)")
## CARA 1 (Paling Gampang): Klik ikon pipet (eyedropper) dan pilih node/Marker2D tujuan di scene
@export var target_node_order: Node2D
@export var target_node_disorder: Node2D

## CARA 2 (Hitung Kotak Tile): Cukup isi jumlah kotak tile (Misal: X = 5 untuk geser 5 kotak ke kanan)
@export var move_in_tiles_order: Vector2 = Vector2.ZERO
@export var move_in_tiles_disorder: Vector2 = Vector2.ZERO
@export var tile_size_pixels: float = 16.0 # Ukuran 1 tile di gamemu (default 16 px)

@export_group("Pengaturan Fisika & Parameter")
@export var one_way: bool = true
@export var move_offset: Vector2 = Vector2.ZERO # Rute manual (Piksel murni) saat ORDER
@export var disorder_offset: Vector2 = Vector2.ZERO # Rute manual (Piksel murni) saat DISORDER
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
@export var shadow_on_order: bool = false
@export var is_treadmill_normal: bool = false
@export var is_treadmill_disorder: bool = false

var origin_pos: Vector2
var history: Array[Vector2] = []
var cur_angle: float = 0.0
var is_falling: bool = false
var has_been_touched: bool = false
var move_timer: float = 0.0
var last_order_state: bool = true

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
		TipePlatform.SHADOW_ORDER: shadow_on_order = true
		TipePlatform.TREADMILL_NORMAL:
			is_treadmill_normal = true
			if conveyor_speed == 0.0: conveyor_speed = 280.0
		TipePlatform.TREADMILL_DISORDER:
			is_treadmill_disorder = true
			if conveyor_speed == 0.0: conveyor_speed = 280.0

	origin_pos = position
	
	if has_node("Gerak"):
		$Gerak.frame = warna_dropdown

	# --- AUTO-KALKULASI RUTE KEMUDAHAN DESAIN LEVEL ---
	# 1. Prioritas 1: Lewat Target Node (Pipet Eyedropper di Inspector)
	if target_node_order:
		move_offset = target_node_order.global_position - global_position
	elif has_node("OrderTarget") and get_node("OrderTarget") is Node2D:
		var target := get_node("OrderTarget") as Node2D
		if target.position != Vector2.ZERO:
			move_offset = target.position
	elif move_in_tiles_order != Vector2.ZERO:
		move_offset = move_in_tiles_order * tile_size_pixels

	if target_node_disorder:
		disorder_offset = target_node_disorder.global_position - global_position
	elif has_node("DisorderTarget") and get_node("DisorderTarget") is Node2D:
		var target := get_node("DisorderTarget") as Node2D
		if target.position != Vector2.ZERO:
			disorder_offset = target.position
	elif move_in_tiles_disorder != Vector2.ZERO:
		disorder_offset = move_in_tiles_disorder * tile_size_pixels
	# --------------------------------------------------

	if has_node("CollisionShape2D"):
		$CollisionShape2D.one_way_collision = one_way
	if has_node("Area2D") and not $Area2D.body_entered.is_connected(_on_area_2d_body_entered):
		$Area2D.body_entered.connect(_on_area_2d_body_entered)

func _physics_process(_delta: float) -> void:
	# Reset state jika pemain mengganti mode agar platform kembali diam seperti awal
	if Global.is_order_phase != last_order_state:
		last_order_state = Global.is_order_phase
		if move_on_touch:
			has_been_touched = false
			position = origin_pos
			move_timer = 0.0

	# 1. Mekanik Pendulum Platform (Ayunan jam)
	if is_pendulum:
		rotation = sin(Time.get_ticks_msec() * 0.001 * (2.0 if Global.is_order_phase else 7.0)) * 0.6

	# 2. Mekanik Shadow Platform (Nyata saat Order, Ilusi/Tembus saat Disorder)
	if shadow_on_disorder:
		modulate.a = 1.0 if Global.is_order_phase else 0.25
		if has_node("CollisionShape2D"):
			$CollisionShape2D.disabled = not Global.is_order_phase

	# 2b. Mekanik Shadow Order (Nyata saat Disorder, Ilusi/Tembus saat Order)
	if shadow_on_order:
		modulate.a = 1.0 if not Global.is_order_phase else 0.25
		if has_node("CollisionShape2D"):
			$CollisionShape2D.disabled = Global.is_order_phase

	# 3. Mekanik Orbit Platform (Berputar mulus dengan akumulasi sudut)
	if orbit_radius > 0:
		cur_angle += _delta * (1.5 if Global.is_order_phase else -5.0) # Disorder berputar terbalik kencang!
		position = origin_pos + Vector2(cos(cur_angle), sin(cur_angle)) * orbit_radius

	# 4. Mekanik Falling Platform (Jatuh saat diinjak)
	if is_falling:
		position.y += _delta * (120.0 if Global.is_order_phase else 380.0)
		if position.y > origin_pos.y + 400.0: is_falling = false; position = origin_pos

	# 5. Mekanik Memory / Time-Reversal Platform (Hanya aktif untuk platform yang bergerak di fase Disorder)
	if is_memory_rewind and disorder_offset != Vector2.ZERO:
		if not Global.is_order_phase:
			history.append(position)
			if history.size() > 300: history.pop_front()
		else:
			if history.size() > 0:
				position = history.pop_back()
			else:
				position = origin_pos
				move_timer = 0.0
			return # STOP! State diperbarui kembali diam sempurna setelah rewind selesai!

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
	trigger_touch(body)

func trigger_touch(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return

	if move_on_touch:
		has_been_touched = true

	# Efek Jatuh namun Garansi Tetap Bisa Lompat
	if fall_on_touch and not is_falling:
		is_falling = true
		if "coyote_timer" in body: body.coyote_timer = 0.5 # Waktu toleransi khusus agar bisa lompat!

	# Efek Trampolin / Lompat Tinggi
	if bounce_power > 0:
		body.velocity = -Global.gravity_direction * bounce_power

	# Efek Hancur / Lenyap Sementara (lalu muncul lagi pas 3 detik)
	if disappear_on_touch and visible:
		await get_tree().create_timer(0.4).timeout # Jeda getar/tunggu sebelum jatuh
		hide()
		if has_node("CollisionShape2D"):
			$CollisionShape2D.set_deferred("disabled", true)
		await get_tree().create_timer(3.0).timeout # Jeda waktu sebelum platform muncul lagi
		show()
		if has_node("CollisionShape2D"):
			$CollisionShape2D.set_deferred("disabled", false)
