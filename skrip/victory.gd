extends Control

@onready var points_label: Label = $VBoxContainer/ScoreCard/MarginContainer/VBox/PointsLabel
@onready var btn_menu: Button = $VBoxContainer/BtnMenu
@onready var btn_restart: Button = $VBoxContainer/BtnRestart
@onready var sound: AudioStreamPlayer2D = $Sound

var time_elapsed: float = 0.0

func _ready() -> void:
	# Pastikan tema visual berada di fase Order (Cerah/Emas) saat tamat
	if not Global.is_order_phase:
		Global.toggle_phase()
		
	if sound:
		sound.play()
		
	points_label.text = "TOTAL KOIN: %d" % Global.points
	
	btn_menu.pressed.connect(func():
		get_tree().change_scene_to_file("res://scene/main_menu.tscn")
	)
	
	btn_restart.pressed.connect(func():
		SaveManager.delete_current_save()
		Global.points = 0
		Global.current_level = 1
		Global.checkpoint_position = Vector2(0, 20)
		get_tree().change_scene_to_file("res://scene/level1.tscn")
	)
	
	# Efek hover elastis (micro-animation)
	for btn in [btn_menu, btn_restart]:
		btn.pivot_offset = btn.custom_minimum_size / 2.0
		btn.mouse_entered.connect(func():
			create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(btn, "scale", Vector2(1.06, 1.06), 0.15)
		)
		btn.mouse_exited.connect(func():
			create_tween().set_trans(Tween.TRANS_SINE).tween_property(btn, "scale", Vector2.ONE, 0.15)
		)
	
	# Efek pop-in kartu skor saat layar dibuka
	$VBoxContainer/ScoreCard.scale = Vector2(0.3, 0.3)
	$VBoxContainer/ScoreCard.pivot_offset = Vector2(200, 50)
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property($VBoxContainer/ScoreCard, "scale", Vector2(1.0, 1.0), 0.6)

func _process(delta: float) -> void:
	time_elapsed += delta
	# Animasi background melayang lambat
	if has_node("Background"):
		$Background.position = Vector2(-80.0 + sin(time_elapsed * 0.4) * 35.0, -60.0 + cos(time_elapsed * 0.3) * 25.0)
	
	# Animasi judul bergelombang gembira
	if has_node("VBoxContainer/TitleBox/MainTitle"):
		var pulse = 1.0 + sin(time_elapsed * 4.0) * 0.04
		$VBoxContainer/TitleBox/MainTitle.scale = Vector2(pulse, pulse)
		$VBoxContainer/TitleBox/MainTitle.pivot_offset = $VBoxContainer/TitleBox/MainTitle.size / 2.0
