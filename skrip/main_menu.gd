extends Control

@onready var btn_continue: Button = $VBoxContainer/BtnContinue
@onready var btn_new: Button = $VBoxContainer/BtnNew
@onready var btn_exit: Button = $VBoxContainer/BtnExit

var bg_order: Texture2D = preload("res://asset/bg_sky2.png")
var bg_disorder: Texture2D = preload("res://asset/bg_sky1.png")

var time_elapsed: float = 0.0
var switch_timer: float = 3.0

func _ready() -> void:
	# Pastikan saat masuk menu mulai di fase Order (Cerah)
	if not Global.is_order_phase:
		Global.toggle_phase()
	_update_theme_color()
	
	btn_continue.visible = FileAccess.file_exists(SaveManager.get_save_path())
	btn_continue.pressed.connect(func(): Global.load_saved_scene())
	
	btn_new.pressed.connect(func():
		SaveManager.delete_current_save()
		Global.points = 0
		Global.current_level = 1
		Global.checkpoint_position = Vector2(0, 20)
		get_tree().change_scene_to_file("res://scene/level1.tscn")
	)
	btn_exit.pressed.connect(func(): get_tree().quit())
	
	# --- EFEK HOVER TOMBOL (MICRO-ANIMATIONS) ---
	for btn in [btn_continue, btn_new, btn_exit]:
		btn.mouse_entered.connect(func():
			btn.pivot_offset = btn.size / 2.0
			create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(btn, "scale", Vector2(1.06, 1.06), 0.15)
		)
		btn.mouse_exited.connect(func():
			create_tween().set_trans(Tween.TRANS_SINE).tween_property(btn, "scale", Vector2.ONE, 0.15)
		)

func _process(delta: float) -> void:
	time_elapsed += delta
	
	# 1. Animasi Background melayang lambat (Parallax Float)
	$Background.position = Vector2(-80.0 + sin(time_elapsed * 0.4) * 40.0, -60.0 + cos(time_elapsed * 0.3) * 30.0)
	
	# 2. Animasi Judul berdenyut elegan (Pulsating Title)
	if has_node("VBoxContainer/TitleBox"):
		$VBoxContainer/TitleBox.pivot_offset = $VBoxContainer/TitleBox.size / 2.0
		var pulse = 1.0 + sin(time_elapsed * 3.5) * 0.03
		$VBoxContainer/TitleBox.scale = Vector2(pulse, pulse)
		
	# 3. Pergantian Mode Order/Disorder Secara Acak tiap beberapa detik!
	switch_timer -= delta
	if switch_timer <= 0:
		switch_timer = randf_range(2.5, 5.0) # Interval acak 2.5 hingga 5 detik
		Global.toggle_phase()
		_update_theme_color()

func _update_theme_color() -> void:
	$Background.texture = bg_order if Global.is_order_phase else bg_disorder
	var target_overlay = Color(0.02, 0.06, 0.15, 0.45) if Global.is_order_phase else Color(0.25, 0.02, 0.06, 0.6)
	var target_subtitle = Color(0.4, 0.85, 1.0) if Global.is_order_phase else Color(1.0, 0.4, 0.5)
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	tween.tween_property($DarkOverlay, "color", target_overlay, 0.4)
	if has_node("VBoxContainer/TitleBox/Subtitle"):
		tween.tween_property($VBoxContainer/TitleBox/Subtitle, "modulate", target_subtitle, 0.4)
