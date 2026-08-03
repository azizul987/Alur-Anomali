extends Sprite2D

@export var order_bg: Texture2D = preload("res://asset/bg_sky2.png")
@export var disorder_bg: Texture2D = preload("res://asset/bg_sky1.png")

func _ready() -> void:
	region_enabled = false
	centered = false
	_update_bg_and_mirror()

func _process(_delta: float) -> void:
	var target_bg = order_bg if Global.is_order_phase else disorder_bg
	if texture != target_bg:
		_update_bg_and_mirror()

func _update_bg_and_mirror() -> void:
	texture = order_bg if Global.is_order_phase else disorder_bg
	
	if texture:
		# Sesuaikan skala secara otomatis berdasarkan resolusi gambar
		if texture.get_width() > 400:
			scale = Vector2(1.5, 1.5) # Untuk bg_sky2 (512x512) -> lebar 768 px
		else:
			scale = Vector2(2.0, 2.0) # Untuk bg_sky1 (358x358) -> lebar 716 px
			
		if get_parent() is ParallaxLayer:
			var layer := get_parent() as ParallaxLayer
			layer.motion_mirroring.x = texture.get_width() * scale.x
			layer.motion_mirroring.y = 0.0
