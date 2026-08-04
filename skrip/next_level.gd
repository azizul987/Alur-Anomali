extends Area2D

@export var next_scene: String = "res://scene/main_menu.tscn"
@export var next_level_number: int = 2
@export var active_texture: Texture2D
@export var inactive_texture: Texture2D

var is_activated: bool = false
var timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if inactive_texture:
		$Sprite2D.texture = inactive_texture
		$Sprite2D.hframes = 1

func _process(delta: float) -> void:
	if is_activated and $Sprite2D.hframes > 1:
		timer += delta
		if timer >= 0.08:
			timer = 0.0
			$Sprite2D.frame = ($Sprite2D.frame + 1) % $Sprite2D.hframes

func _on_body_entered(body: Node2D) -> void:
	if not is_activated and body is CharacterBody2D:
		is_activated = true
		
		if has_node("Sound"):
			$Sound.play()
		
		if active_texture:
			$Sprite2D.texture = active_texture
			$Sprite2D.hframes = int(active_texture.get_width() / 64.0) # Otomatis hitung frame dari resolusi gambar
			$Sprite2D.frame = 0
			
		# Jeda singkat agar suara dan efek terputar sebelum lanjut level & simpan otomatis
		get_tree().create_timer(0.8).timeout.connect(func():
			Global.change_level(next_level_number, next_scene)
		)
