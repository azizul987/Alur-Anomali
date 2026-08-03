extends AnimatableBody2D

@export var one_way: bool = true
@export var move_offset: Vector2 = Vector2.ZERO # Rute saat ORDER (Stabil, misal horizontal)
@export var disorder_offset: Vector2 = Vector2.ZERO # Rute saat DISORDER (Kacau/Melayang atas)
@export var move_speed: float = 2.0 # Kecepatan ayunan
@export var bounce_power: float = 0.0 # Isi misal 600.0 untuk jadi trampolin
@export var disappear_on_touch: bool = false # Centang jika ingin hancur saat diinjak & muncul lagi
@export var is_pendulum: bool = false # Ayunan jam metronom
@export var shadow_on_disorder: bool = false # Nyata saat Order, tembus (bayangan) saat Disorder
@export var orbit_radius: float = 0.0 # Berputar 360 derajat mengitari titik awal
@export var conveyor_speed: float = 0.0 # Ban berjalan / angin pendorong
@export var is_ice: bool = false # Permukaan es licin (dicek oleh player.gd)
@export var is_memory_rewind: bool = false # Merekam rute lalu rewind mundur saat fase Order
@export var fall_on_touch: bool = false # Jatuh saat diinjak namun pemain tetap berhak melompat

var origin_pos: Vector2
var history: Array[Vector2] = []
var cur_angle: float = 0.0
var is_falling: bool = false

func _ready() -> void:
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

	# 6. Mekanik Moving Platform Metronome: Pilih rute Order atau Disorder
	if move_offset != Vector2.ZERO or disorder_offset != Vector2.ZERO:
		var target_offset = move_offset if Global.is_order_phase else disorder_offset
		var target = origin_pos + target_offset * sin(Time.get_ticks_msec() * 0.001 * move_speed)
		position = position.lerp(target, 0.1)

# Hubungkan sinyal "body_entered" dari node Area2D di platform ke fungsi ini
func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return

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
