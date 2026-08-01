extends CharacterBody2D

const SPEED = 200.0
const JUMP_POWER = -400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func  _ready() -> void:
	SaveManager.load_game()
	global_position=Global.checkpoint_position

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_POWER

	var direction = Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = 0

	move_and_slide()
	Global.checkpoint_position=global_position
	SaveManager.save_game()
