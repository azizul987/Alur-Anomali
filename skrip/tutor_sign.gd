extends Area2D

@export_multiline var message: String = "Tekan [M] untuk ganti mode"
@export var show_icon_marker: bool = true

var time_elapsed: float = 0.0
@onready var tooltip: Control = $Tooltip
@onready var label_text: Label = $Tooltip/PanelContainer/MarginContainer/Label
@onready var marker: Label = $Marker
@onready var sound: AudioStreamPlayer2D = $Sound

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	label_text.text = message
	tooltip.visible = false
	tooltip.modulate.a = 0.0
	tooltip.scale = Vector2(0.8, 0.8)
	
	if not show_icon_marker:
		marker.visible = false

func _process(delta: float) -> void:
	# Animasi melayang santai untuk ikon penanda "[ ! ]"
	if show_icon_marker and marker.visible:
		time_elapsed += delta
		marker.position.y = -15.0 + sin(time_elapsed * 4.0) * 4.0
		
	# Update teks jika diatur ulang di Inspector
	if label_text.text != message:
		label_text.text = message
		tooltip.size = Vector2.ZERO # Paksa Godot menyesuaikan ulang ukuran kontainernya

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		if sound and not tooltip.visible:
			sound.play()
		
		tooltip.visible = true
		# Pusatkan animasi zoom dari tengah bawah gelembung pesan
		tooltip.pivot_offset = Vector2(tooltip.size.x / 2.0, tooltip.size.y)
		var t = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(tooltip, "modulate:a", 1.0, 0.25)
		t.tween_property(tooltip, "scale", Vector2(1.0, 1.0), 0.25)

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		var t = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
		t.tween_property(tooltip, "modulate:a", 0.0, 0.2)
		t.tween_property(tooltip, "scale", Vector2(0.8, 0.8), 0.2)
		t.chain().tween_callback(func(): tooltip.visible = false)
