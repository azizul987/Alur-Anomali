extends AnimatableBody2D

@export var one_way: bool = true
@export var move_offset: Vector2 = Vector2.ZERO # Rute saat ORDER (Stabil, misal horizontal)
@export var disorder_offset: Vector2 = Vector2.ZERO # Rute saat DISORDER (Kacau/Melayang atas)
@export var move_speed: float = 2.0 # Kecepatan ayunan
@export var bounce_power: float = 0.0 # Isi misal 600.0 untuk jadi trampolin
@export var disappear_on_touch: bool = false # Centang jika ingin hancur saat diinjak & muncul lagi

var origin_pos: Vector2

func _ready() -> void:
	origin_pos = position
	if has_node("CollisionShape2D"):
		$CollisionShape2D.one_way_collision = one_way

func _physics_process(_delta: float) -> void:
	# Mekanik Metronome: Pilih rute Order (stabil) atau Disorder (melayang/kacau)
	var target_offset = move_offset if Global.is_order_phase else disorder_offset
	if target_offset != Vector2.ZERO or position.distance_to(origin_pos) > 1.0:
		var target = origin_pos + target_offset * sin(Time.get_ticks_msec() * 0.001 * move_speed)
		position = position.lerp(target, 0.1)

# Hubungkan sinyal "body_entered" dari node Area2D di platform ke fungsi ini
func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return

	# 3. Efek Trampolin / Lompat Tinggi
	if bounce_power > 0:
		body.velocity = -Global.gravity_direction * bounce_power

	# 4. Efek Hancur / Lenyap Sementara (lalu muncul lagi pas 3 detik)
	if disappear_on_touch:
		await get_tree().create_timer(0.4).timeout # Jeda getar/tunggu sebelum jatuh
		hide()
		$CollisionShape2D.set_deferred("disabled", true)
		await get_tree().create_timer(3.0).timeout # Jeda waktu sebelum platform muncul lagi
		show()
		$CollisionShape2D.set_deferred("disabled", false)
