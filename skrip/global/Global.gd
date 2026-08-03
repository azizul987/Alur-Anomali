extends Node

var current_level: int = 1
var checkpoint_position: Vector2 = Vector2.ZERO
var current_rule: int = 0
var gravity_direction: Vector2 = Vector2.UP
var death_count: int = 0

# --- PROTOTYPE MEKANIK METRONOME & EFEK TRANSISI ---
var is_order_phase: bool = true # True = Order (Tick), False = Disorder (Tock)
var canvas_mod: CanvasModulate
var shader_mat: ShaderMaterial

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
# ----------------------------------------------------
			
func _input(event: InputEvent) -> void:
	# Ganti mode Order <-> Disorder via custom input "toggle_metronome" (Diatur di Project Settings)
	if event.is_action_pressed("toggle_metronome"):
		toggle_phase()

	if event.is_action_pressed("change_grav") and Debug.is_active():
		Global.gravity_direction = Global.gravity_direction.rotated(PI / 2.0).round()
	if event.is_action_pressed("reset_save"):
		SaveManager.delete_current_save()
