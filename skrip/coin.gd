extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		Global.points += 1
		if has_node("Sound") and get_node("Sound").stream != null:
			get_node("Sound").play()
		else:
			Global.play_sfx("res://asset/brackeys_platformer_assets/sounds/coin.wav", -5.0)
		$Sprite2D.hide()
		$CollisionShape2D.set_deferred("disabled", true)
		if has_node("Sound") and get_node("Sound").stream != null:
			await get_node("Sound").finished
		queue_free()
