extends HBoxContainer

func start_new_day() -> void:
	for slot in get_children():
		slot.clear_slot()
