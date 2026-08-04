extends Node

var current_level: int = 1
var checkpoint_position: Vector2 = Vector2.ZERO
var current_rule: int = 0
var gravity_direction: Vector2 = Vector2.UP
var death_count: int = 0
var points: int = 0 # Menyimpan perolehan skor koin

# --- PROTOTYPE MEKANIK METRONOME & EFEK TRANSISI ---
var is_order_phase: bool = true # True = Order (Tick), False = Disorder (Tock)
var canvas_mod: CanvasModulate
var shader_mat: ShaderMaterial
var bgm_player: AudioStreamPlayer
var sfx_transition: AudioStreamPlayer

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

func toggle_phase() -> void:
	is_order_phase = not is_order_phase
	if is_order_phase:
		gravity_direction = Vector2.DOWN # Gravitasi stabil ke bawah saat Order

	# --- EFEK VISUAL TRANSISI (TWEENING) ---
	var target_color = Color.WHITE if is_order_phase else Color(0.7, 0.35, 0.45) # Order: Cerah | Disorder: Merah meremang
	var tween_color = create_tween()
	if canvas_mod:
		tween_color.tween_property(canvas_mod, "color", target_color, 0.35).set_trans(Tween.TRANS_SINE)
	
	if shader_mat:
		shader_mat.set_shader_parameter("effect_strength", 1.0) # Pemicu gelombang glitch kejut
		var tween_shader = create_tween()
		tween_shader.tween_method(func(val): shader_mat.set_shader_parameter("effect_strength", val), 1.0, 0.0, 0.4).set_trans(Tween.TRANS_CUBIC)

	# --- EFEK AUDIO TRANSISI (PITCH SHIFT & SFX) ---
	if sfx_transition and sfx_transition.stream:
		sfx_transition.pitch_scale = 1.1 if is_order_phase else 0.85
		sfx_transition.play()
		
	if bgm_player:
		var tween_audio = create_tween()
		var target_pitch = 1.0 if is_order_phase else 0.84 # Order cerah ceria, Disorder agak merendah misterius
		tween_audio.tween_property(bgm_player, "pitch_scale", target_pitch, 0.35).set_trans(Tween.TRANS_SINE)
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
func change_level(new_level: int, scene_path: String) -> void:
	current_level = new_level
	checkpoint_position = Vector2.ZERO # Reset posisi checkpoint saat masuk scene level baru
	SaveManager.save_game()
	get_tree().change_scene_to_file(scene_path)

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
