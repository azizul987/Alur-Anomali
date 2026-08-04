extends Node

var current_level: int = 1
var checkpoint_position: Vector2 = Vector2.ZERO
var current_rule: int = 0
var gravity_direction: Vector2 = Vector2.UP
var death_count: int = 0
var points: int = 0 # Menyimpan perolehan skor koin
var collected_coins: Dictionary = {} # Menyimpan ID koin yang sudah didapatkan agar tidak muncul lagi

# --- PROTOTYPE MEKANIK METRONOME & EFEK TRANSISI ---
var is_order_phase: bool = true # True = Order (Tick), False = Disorder (Tock)
var canvas_mod: CanvasModulate
var shader_mat: ShaderMaterial
var bgm_player: AudioStreamPlayer
var sfx_transition: AudioStreamPlayer
var anomaly_drone: AudioStreamPlayer
var sfx_button_click: AudioStreamPlayer
var disorder_timer: float = 0.0 # Menghitung lama tinggal di mode non-normal (Disorder)
var darkness_overlay: ColorRect # Overlay layar untuk menjamin efek semakin gelap pasti kelihatan nyata!
var transition_layer: CanvasLayer
var transition_rect: ColorRect
var is_transitioning: bool = false

signal reset_trap

func _ready() -> void:
	# 1. Pasang pengubah warna atmosfer dunia (CanvasModulate)
	canvas_mod = CanvasModulate.new()
	add_child(canvas_mod)
	canvas_mod.color = Color.WHITE # Warna default saat Order
	
	# 2. Pasang wadah efek shader layar (Post-Processing)
	var c_layer = CanvasLayer.new()
	c_layer.layer = 10 # Berada di atas grafis permainan
	add_child(c_layer)
	
	var screen_rect = ColorRect.new()
	screen_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # Agar tidak mengganggu input
	c_layer.add_child(screen_rect)
	
	darkness_overlay = ColorRect.new()
	darkness_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	darkness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	darkness_overlay.color = Color(0.02, 0.0, 0.05, 0.0) # Bening transparan saat kondisi normal
	c_layer.add_child(darkness_overlay)
	
	shader_mat = ShaderMaterial.new()
	shader_mat.shader = load("res://skrip/shader/transition.gdshader")
	screen_rect.material = shader_mat
	
	# 3. Pasang HUD antarmuka UI (Poin & Level) secara global dan otomatis ke dalam game
	var ui_scene = load("res://scene/ui.tscn")
	if ui_scene:
		add_child(ui_scene.instantiate())

	# 4. Pasang Sistem Musik Latar & Efek Suara (BGM & SFX) secara global
	bgm_player = AudioStreamPlayer.new()
	var music_stream = load("res://asset/brackeys_platformer_assets/music/time_for_adventure.mp3")
	if music_stream:
		if music_stream is AudioStreamMP3:
			music_stream.loop = true # Putar tanpa henti abadi di latar belakang!
		bgm_player.stream = music_stream
		bgm_player.volume_db = -8.0 # Volume nyaman tidak berisik
		bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(bgm_player)
		bgm_player.play()
		
	sfx_transition = AudioStreamPlayer.new()
	var trans_stream = load("res://asset/brackeys_platformer_assets/sounds/power_up.wav")
	if trans_stream:
		sfx_transition.stream = trans_stream
		sfx_transition.volume_db = -5.0
		add_child(sfx_transition)
		
	# 5. Pasang suara gemuruh atmosfer anomali (Drone Low Frequency)
	anomaly_drone = AudioStreamPlayer.new()
	var drone_stream = load("res://asset/brackeys_platformer_assets/sounds/explosion.wav")
	if drone_stream:
		if drone_stream is AudioStreamWAV:
			drone_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		anomaly_drone.stream = drone_stream
		anomaly_drone.volume_db = -80.0 # Hening total padaawalnya
		anomaly_drone.pitch_scale = 0.25 # Distorsi suara sangat rendah
		anomaly_drone.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(anomaly_drone)

	# 6. Pasang efek suara tombol menu (Button Click SFX) dan hubungkan ke semua tombol!
	sfx_button_click = AudioStreamPlayer.new()
	var tap_stream = load("res://asset/brackeys_platformer_assets/sounds/tap.wav")
	if tap_stream:
		sfx_button_click.stream = tap_stream
		sfx_button_click.volume_db = 2.0
		sfx_button_click.process_mode = Node.PROCESS_MODE_ALWAYS # Agar tetap berbunyi saat game di-pause!
		add_child(sfx_button_click)
		
	# 7. Pasang sistem transisi layar (Screen Fade Transition & Startup Boot)
	transition_layer = CanvasLayer.new()
	transition_layer.layer = 120 # Berada di atas segala elemen grafis dan UI
	add_child(transition_layer)
	
	transition_rect = ColorRect.new()
	transition_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_rect.color = Color(0.04, 0.02, 0.08, 1.0) # Layar gelap mistis saat game baru boot
	transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	transition_layer.add_child(transition_rect)
	
	# Fade In halus saat start awal game dibuka!
	var boot_tween = create_tween()
	boot_tween.tween_interval(0.2) # Beri waktu render
	boot_tween.tween_property(transition_rect, "color:a", 0.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	boot_tween.tween_callback(func(): transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE)
	
	if get_tree():
		get_tree().node_added.connect(_on_node_added)
		_connect_buttons_recursive(get_tree().root)

func play_click_sfx() -> void:
	if sfx_button_click:
		sfx_button_click.pitch_scale = randf_range(0.95, 1.05) # Efek klik renyah alami
		sfx_button_click.play()

func _on_node_added(node: Node) -> void:
	if node is Button or node is TextureButton or node is LinkButton:
		if not node.pressed.is_connected(play_click_sfx):
			node.pressed.connect(play_click_sfx)
	_connect_buttons_recursive(node)

func _connect_buttons_recursive(node: Node) -> void:
	if node is Button or node is TextureButton or node is LinkButton:
		if not node.pressed.is_connected(play_click_sfx):
			node.pressed.connect(play_click_sfx)
	for child in node.get_children():
		_connect_buttons_recursive(child)

func _process(delta: float) -> void:
	# Efek kegelapan bertahap & distorsi musik saat tinggal di mode Disorder (Non-Normal)
	var current_scene = get_tree().current_scene if get_tree() else null
	if current_scene and not is_order_phase:
		var path_lower = current_scene.scene_file_path.to_lower() if current_scene.scene_file_path else ""
		if not ("menu" in path_lower or "victory" in path_lower):
			disorder_timer += delta
			# Dipersingkat dari 20 detik menjadi 7 detik agar kegelapan pekat terasa cepat memburu pemain!
			var t = clampf(disorder_timer / 7.0, 0.0, 1.0)
			
			# Gelapkan dunia ganda: CanvasModulate + Darkness Overlay se-layar penuh!
			if canvas_mod:
				canvas_mod.color = Color(0.7, 0.35, 0.45).lerp(Color(0.1, 0.05, 0.1), t)
			if darkness_overlay:
				darkness_overlay.color = Color(0.02, 0.0, 0.06, lerpf(0.0, 0.82, t))
				
			if bgm_player:
				bgm_player.pitch_scale = lerpf(0.84, 0.55, t)
				
			if anomaly_drone and disorder_timer > 0.3:
				if not anomaly_drone.playing:
					anomaly_drone.play()
				anomaly_drone.volume_db = lerpf(-40.0, -10.0, clampf((disorder_timer - 0.3) / 6.0, 0.0, 1.0))
				anomaly_drone.pitch_scale = lerpf(0.35, 0.18, t)

func toggle_phase() -> void:
	is_order_phase = not is_order_phase
	disorder_timer = 0.0 # Reset waktu kegelapan anomali
	
	if is_order_phase:
		gravity_direction = Vector2.DOWN # Gravitasi stabil ke bawah saat Order

	# --- EFEK VISUAL TRANSISI (TWEENING) ---
	var target_color = Color.WHITE if is_order_phase else Color(0.7, 0.35, 0.45) # Order: Cerah | Disorder: Merah meremang
	var tween_color = create_tween()
	if canvas_mod:
		tween_color.tween_property(canvas_mod, "color", target_color, 0.35).set_trans(Tween.TRANS_SINE)
	if darkness_overlay and is_order_phase:
		var tween_dark = create_tween()
		tween_dark.tween_property(darkness_overlay, "color:a", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC)
	
	if shader_mat:
		shader_mat.set_shader_parameter("effect_strength", 1.0) # Pemicu gelombang glitch kejut
		var tween_shader = create_tween()
		tween_shader.tween_method(func(val): shader_mat.set_shader_parameter("effect_strength", val), 1.0, 0.0, 0.4).set_trans(Tween.TRANS_CUBIC)

	var cam = get_viewport().get_camera_2d()
	if cam:
		create_tween().tween_method(func(v): cam.offset = Vector2(randf_range(-v, v), randf_range(-v, v)), 8.0, 0.0, 0.25)

	# --- EFEK AUDIO TRANSISI (PITCH SHIFT & SFX) ---
	if sfx_transition and sfx_transition.stream:
		sfx_transition.pitch_scale = 1.1 if is_order_phase else 0.85
		sfx_transition.play()
		
	if bgm_player:
		var tween_audio = create_tween()
		var target_pitch = 1.0 if is_order_phase else 0.84 # Order cerah ceria, Disorder agak merendah misterius
		tween_audio.tween_property(bgm_player, "pitch_scale", target_pitch, 0.35).set_trans(Tween.TRANS_SINE)
		
	if anomaly_drone and anomaly_drone.playing:
		if is_order_phase:
			var tween_drone = create_tween()
			tween_drone.tween_property(anomaly_drone, "volume_db", -80.0, 0.35)
			tween_drone.tween_callback(anomaly_drone.stop)
# ----------------------------------------------------
			
func _input(event: InputEvent) -> void:
	# Ganti mode Order <-> Disorder via custom input "toggle_metronome" (Diatur di Project Settings)
	if event.is_action_pressed("toggle_metronome"):
		toggle_phase()

	if event.is_action_pressed("change_grav") and Debug.is_active():
		Global.gravity_direction = Global.gravity_direction.rotated(PI / 2.0).round()
	if event.is_action_pressed("reset_save"):
		SaveManager.delete_current_save()

# --- HELPER PINDAH SCENE & SAVE GAME ---
func reset_game_state() -> void:
	points = 0
	current_level = 1
	checkpoint_position = Vector2(0, 20)
	collected_coins.clear()
	SaveManager.delete_current_save()

func change_level(new_level: int, scene_path: String) -> void:
	current_level = new_level
	checkpoint_position = Vector2.ZERO # Reset posisi checkpoint saat masuk scene level baru
	SaveManager.save_game()
	transition_to_scene(scene_path)

func transition_to_scene(scene_path: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	if transition_rect:
		transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP # Blokir input ganda selama transisi
		var tween_out = create_tween()
		tween_out.tween_property(transition_rect, "color:a", 1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween_out.tween_callback(func():
			get_tree().change_scene_to_file(scene_path)
			var tween_in = create_tween()
			tween_in.tween_interval(0.1) # Jeda pemuatan scene baru
			tween_in.tween_property(transition_rect, "color:a", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween_in.tween_callback(func():
				transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				is_transitioning = false
			)
		)
	else:
		get_tree().change_scene_to_file(scene_path)
		is_transitioning = false

func reload_scene() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	if transition_rect:
		transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		var tween_out = create_tween()
		tween_out.tween_property(transition_rect, "color:a", 1.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween_out.tween_callback(func():
			get_tree().reload_current_scene()
			var tween_in = create_tween()
			tween_in.tween_interval(0.1)
			tween_in.tween_property(transition_rect, "color:a", 0.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween_in.tween_callback(func():
				transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				is_transitioning = false
			)
		)
	else:
		get_tree().reload_current_scene()
		is_transitioning = false

func load_saved_scene() -> void:
	SaveManager.load_game(true) # Argumen true memicu perpindahan scene jika berbeda dari yang tersimpan

# --- HELPER EFEK SUARA (SFX) GLOBAL ---
func play_sfx(sfx_path: String, vol_db: float = -4.0) -> void:
	var stream = load(sfx_path)
	if stream:
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.stream = stream
		sfx_player.volume_db = vol_db
		add_child(sfx_player)
		sfx_player.play()
		sfx_player.finished.connect(sfx_player.queue_free)
