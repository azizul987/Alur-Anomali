extends CharacterBody2D

const SPEED = 200.0
const JUMP_POWER = 400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	SaveManager.load_game()
	global_position = Global.checkpoint_position
	
func _physics_process(delta):
	up_direction = -Global.gravity_direction
	rotation = Vector2.DOWN.angle_to(Global.gravity_direction)
	if not is_on_floor():
		velocity += gravity * delta * Global.gravity_direction

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity -= Global.gravity_direction * JUMP_POWER

	var direction = Input.get_axis("ui_left", "ui_right")

	# Gravitasi kiri atau kanan.
	if Global.gravity_direction.x != 0:
		velocity.y = direction * SPEED

	# Gravitasi atas atau bawah.
	else:
		velocity.x = direction * SPEED

	move_and_slide()

	Global.checkpoint_position = global_position
	SaveManager.save_game()
