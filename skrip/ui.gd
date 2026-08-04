extends CanvasLayer

@onready var points_label: Label = $HUD/TopLeft/RowCoins/PointsLabel
@onready var level_label: Label = $HUD/TopLeft/LevelLabel

func _process(_delta: float) -> void:
	var curr_scene = get_tree().current_scene if get_tree() else null
	visible = is_instance_valid(curr_scene) and not ("main_menu" in curr_scene.scene_file_path)
	points_label.text = "%d" % Global.points
	level_label.text = "Level %d" % Global.current_level
