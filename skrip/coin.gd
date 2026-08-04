extends Area2D

func _ready() -> void:
	if Global.collected_coins.has(_get_coin_id()):
		queue_free()

func _get_coin_id() -> String:
	var scene_path = get_tree().current_scene.scene_file_path if get_tree() and get_tree().current_scene else "unknown_level"
	return "%s_%s_%d_%d" % [scene_path, name, int(global_position.x), int(global_position.y)]

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		Global.collected_coins[_get_coin_id()] = true
		Global.points += 1
		SaveManager.save_game() # Langsung simpan pencapaian ke sistem
		if has_node("Sound") and get_node("Sound").stream != null:
			get_node("Sound").play()
		else:
			Global.play_sfx("res://asset/brackeys_platformer_assets/sounds/coin.wav", -5.0)
		$Sprite2D.hide()
		$CollisionShape2D.set_deferred("disabled", true)
		if has_node("Sound") and get_node("Sound").stream != null:
			await get_node("Sound").finished
		queue_free()

