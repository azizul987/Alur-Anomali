extends AnimatableBody2D

@export var one_way: bool = true
@export var move_offset: Vector2 = Vector2.ZERO # Isi misal (150, 0) untuk gerak kanan-kiri
@export var move_duration: float = 2.0
@export var bounce_power: float = 0.0 # Isi misal 600.0 untuk jadi trampolin
@export var disappear_on_touch: bool = false # Centang jika ingin hancur saat diinjak & muncul lagi

var origin_pos: Vector2

func _ready() -> void:
	origin_pos = position
	# 1. Atur kolisi satu arah dari bawah (One-Way)
	if has_node("CollisionShape2D"):
		$CollisionShape2D.one_way_collision = one_way
		
	# 2. Gerak bolak-balik otomatis (Tween) jika move_offset diisi
	if move_offset != Vector2.ZERO:
		var tween = create_tween().set_loops()
		tween.tween_property(self, "position", origin_pos + move_offset, move_duration).set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "position", origin_pos, move_duration).set_trans(Tween.TRANS_SINE)

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
