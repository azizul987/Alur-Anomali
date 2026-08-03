extends Area2D

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
		if timer >= 0.05:
			timer = 0.0
			$Sprite2D.frame = ($Sprite2D.frame + 1) % $Sprite2D.hframes

func _on_body_entered(body: Node2D) -> void:
	if not is_activated and body is CharacterBody2D:
		is_activated = true
		Global.checkpoint_position = global_position
		if "start_position" in body:
			body.start_position = global_position
		SaveManager.save_game()
		
		if has_node("Sound"):
			$Sound.play()
		
		# Ganti ke animasi bendera berkobar (10 frame di 64x64)
		if active_texture:
			$Sprite2D.texture = active_texture
			$Sprite2D.hframes = 10
			$Sprite2D.frame = 0
