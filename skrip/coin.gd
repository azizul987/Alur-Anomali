extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		Global.points += 1
		$Sound.play()
		$Sprite2D.hide()
		$CollisionShape2D.set_deferred("disabled", true)
		await $Sound.finished
		queue_free()
