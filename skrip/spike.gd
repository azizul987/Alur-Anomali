extends Node2D

@export var can_fly_trigger: bool = true
@export var spike_visible: bool = true

var fly_height: float = 200.0
var fly_speed: float = 1.0
var has_fired: bool = false


var active_tween: Tween 
var is_resetting: bool = false 
@onready var visual_node = $VisualParent
@onready var damage_hitbox = $VisualParent/Damage/CollisionShape2D

func _ready():
	Global.reset_trap.connect(reset)
	
func _process(delta: float) -> void:
	update_spike_state()


func reset():
	is_resetting = true 
	if active_tween and active_tween.is_running():
		active_tween.kill()
	has_fired = false
	visual_node.position.y = 0
	await get_tree().physics_frame
	is_resetting = false 
	
func update_spike_state():
	var should_hide = (!spike_visible and Global.is_order_phase)
	$VisualParent/Sprite2D.visible = !should_hide
	if damage_hitbox and damage_hitbox.disabled != should_hide:
		damage_hitbox.disabled = should_hide

func _on_damage_body_entered(body: Node2D) -> void:
	if body.has_method("mati"):
		body.mati()
		
func _on_trigger_body_entered(body: Node2D) -> void:
	if body.name == "Player" and !Global.is_order_phase and not has_fired and can_fly_trigger and not is_resetting:
		launch_spike()
		
func launch_spike():
	has_fired = true
	
	active_tween = get_tree().create_tween()
	active_tween.tween_property(visual_node, "position:y", -fly_height, fly_speed)\
	.set_trans(Tween.TRANS_QUINT)\
	.set_ease(Tween.EASE_OUT)
