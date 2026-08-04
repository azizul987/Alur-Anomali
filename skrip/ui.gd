extends CanvasLayer

@onready var points_label: Label = $HUD/TopLeft/RowCoins/PointsLabel
@onready var level_label: Label = $HUD/TopLeft/LevelLabel

var pause_overlay: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Pastikan UI tetap beroperasi saat game di-pause!
	setup_pause_menu()

func _process(_delta: float) -> void:
	var curr_scene = get_tree().current_scene if get_tree() else null
	var is_in_game = is_instance_valid(curr_scene) and not ("main_menu" in curr_scene.scene_file_path or "victory" in curr_scene.scene_file_path)
	visible = is_in_game
	points_label.text = "%d" % Global.points
	level_label.text = "Level %d" % Global.current_level
	
	# Jika berada di main menu atau victory, pastikan status game tidak terpantau pause
	if not is_in_game and get_tree() and get_tree().paused:
		set_paused_state(false)

func _input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		set_paused_state(not get_tree().paused)

func set_paused_state(target_pause: bool) -> void:
	get_tree().paused = target_pause
	if pause_overlay:
		pause_overlay.visible = target_pause
	if target_pause:
		Global.play_sfx("res://asset/brackeys_platformer_assets/sounds/tap.wav", -4.0)

func setup_pause_menu() -> void:
	var font_pixel = load("res://object/BPdotsSquareBold.otf")
	
	pause_overlay = Control.new()
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP # Blokir input ke game di belakangnya
	pause_overlay.visible = false
	add_child(pause_overlay)
	
	# Latar belakang gelap semitransparan elegan
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.06, 0.15, 0.75)
	pause_overlay.add_child(bg)
	
	# Wadah utama di tengah layar
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)
	
	# Judul Pause (Dalam Bahasa Indonesia & Font Pixel)
	var title = Label.new()
	title.text = "PERMAINAN DIJEDA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_pixel:
		title.add_theme_font_override("font", font_pixel)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 8)
	vbox.add_child(title)
	
	# Spacer
	var space = Control.new()
	space.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(space)
	
	# Tombol 1: Lanjutkan
	var btn_resume = create_menu_button("LANJUTKAN PERMAINAN", font_pixel)
	btn_resume.pressed.connect(func():
		Global.play_sfx("res://asset/brackeys_platformer_assets/sounds/tap.wav")
		set_paused_state(false)
	)
	vbox.add_child(btn_resume)
	
	# Tombol 2: Mulai Ulang Level
	var btn_restart = create_menu_button("MULAI ULANG LEVEL", font_pixel)
	btn_restart.pressed.connect(func():
		Global.play_sfx("res://asset/brackeys_platformer_assets/sounds/tap.wav")
		set_paused_state(false)
		get_tree().reload_current_scene()
	)
	vbox.add_child(btn_restart)
	
	# Tombol 3: Kembali ke Menu Utama
	var btn_menu = create_menu_button("KEMBALI KE MENU UTAMA", font_pixel)
	btn_menu.pressed.connect(func():
		Global.play_sfx("res://asset/brackeys_platformer_assets/sounds/tap.wav")
		set_paused_state(false)
		SaveManager.save_game()
		get_tree().change_scene_to_file("res://scene/main_menu.tscn")
	)
	vbox.add_child(btn_menu)

func create_menu_button(btn_text: String, font_pixel: Font) -> Button:
	var btn = Button.new()
	btn.text = btn_text
	btn.custom_minimum_size = Vector2(280, 48)
	btn.focus_mode = Control.FOCUS_NONE
	if font_pixel:
		btn.add_theme_font_override("font", font_pixel)
	btn.add_theme_font_size_override("font_size", 16)
	
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.4, 1))
	btn.add_theme_color_override("font_outline_color", Color.BLACK)
	btn.add_theme_constant_override("outline_size", 4)
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.172, 0.372, 0.2, 0.92)
	style_normal.border_width_left = 2; style_normal.border_width_top = 2
	style_normal.border_width_right = 2; style_normal.border_width_bottom = 2
	style_normal.border_color = Color.BLACK
	style_normal.corner_radius_top_left = 8; style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_right = 8; style_normal.corner_radius_bottom_left = 8
	style_normal.shadow_color = Color(0, 0, 0, 0.3); style_normal.shadow_size = 4
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.24, 0.52, 0.28, 0.95)
	style_hover.border_color = Color(1, 0.9, 0.3, 1) # Border kuning terang saat dihover
	style_hover.shadow_color = Color(0, 0, 0, 0.45); style_hover.shadow_size = 6
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.12, 0.26, 0.14, 0.95)
	style_pressed.shadow_color = Color(0, 0, 0, 0.2); style_pressed.shadow_size = 2
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", style_normal)
	return btn
