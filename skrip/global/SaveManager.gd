extends Node

var current_slot := 1
var default_slot := 1


func set_slot(slot: int) -> void:
	current_slot = slot
	#print("Slot aktif:", current_slot)


func create_new_slot(slot: int) -> void:
	current_slot = slot
	write_save_data({"chpos": Vector2.ZERO})


func get_save_path() -> String:
	return "user://save_slot_%d.json" % current_slot


func get_all_slots() -> Array:
	var slots := []
	for i in range(1, 100):
		var file_path = "user://save_slot_%d.json" % i
		if FileAccess.file_exists(file_path):
			var data := get_save_data(i)
			data["slot"] = i
			slots.append(data)
	return slots


func get_save_data(slot: int) -> Dictionary:
	var path := "user://save_slot_%d.json" % slot
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text()
	var json := JSON.new()
	var err := json.parse(content)
	if err != OK:
		return {}

	var result = json.get_data()
	if result is Dictionary:
		return result
	return {}


func get_active_slot_display_text() -> String:
	return "Slot %d" % current_slot


func read_save_data() -> Dictionary:
	var path := get_save_path()

	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())

	if data == null:
		return {}

	return data


func write_save_data(data: Dictionary) -> void:
	var file := FileAccess.open(get_save_path(), FileAccess.WRITE)
	file.store_string(JSON.stringify(data))


func save_game() -> void:
	var data := read_save_data()
	data["chpos"] = {
		"x":Global.checkpoint_position.x,
		"y":Global.checkpoint_position.y
	}
	data["gravity_direction"] = {
		"x":Global.gravity_direction.x,
		"y":Global.gravity_direction.y
	}

	#data["skill_tree_camera"]={
		#"x":Point.skill_tree_camera.x,
		#"y":Point.skill_tree_camera.y,
		#"z":Point.skill_tree_camera.z
	#}
	#data["main_camera"]={
		#"x":Point.main_tree_camera.x,
		#"y":Point.main_tree_camera.y,
		#"z":Point.main_tree_camera.z
	#}
	#data["tipe_wilayah"]={
		#"x":Point.TipeWilayahArray.x,
		#"y":Point.TipeWilayahArray.y,
		#"z":Point.TipeWilayahArray.z
	#}
	
	write_save_data(data)
	#print("Point saved")


func load_game() -> void:
	var data := read_save_data()
	var checkpoint_position=data.get("chpos",Vector2(0,0))
	Global.checkpoint_position=Vector2(
		checkpoint_position.x,
		checkpoint_position.y
	)
	var gravity_direction=data.get("gravity_direction",Vector2.DOWN)
	Global.gravity_direction=Vector2(
		gravity_direction.x,
		gravity_direction.y
	)
	#Point.point = float(data.get("point", 0))
	#var cam_data:Dictionary=data.get("skill_tree_camera",{
		#"x":0.0,
		#"y":0.0,
		#"z":1.4
	#})
	##Point.skill_tree_camera=Vector3(
		#float(cam_data.get("x")),
		#float(cam_data.get("y")),
		#float(cam_data.get("z"))
	#)


func delete_current_save() -> void:
	var path := get_save_path()

	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("Save slot", current_slot, "berhasil dihapus")
	else:
		print("Save slot", current_slot, "memang belum ada")

func get_all_used_slots() -> Array[int]:
	var slots: Array[int] = []
	var dir := DirAccess.open("user://")
	if dir == null:
		return slots
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("save_slot_") and file_name.ends_with(".json"):
			var num_str := file_name.trim_prefix("save_slot_").trim_suffix(".json")
			if num_str.is_valid_int():
				slots.append(int(num_str))
		file_name = dir.get_next()
	dir.list_dir_end()
	slots.sort()
	return slots

func get_next_available_slot() -> int:
	var used_slots := get_all_used_slots()
	var next_slot := 1
	while used_slots.has(next_slot):
		next_slot += 1
	return next_slot

func delete_slot(slot: int) -> void:
	var path := "user://save_slot_%d.json" % slot
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
