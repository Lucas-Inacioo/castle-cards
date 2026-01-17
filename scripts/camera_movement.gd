extends Camera2D

#region Camera Constants
const MAX_ZOOM_IN := 0.5
const MAX_ZOOM_OUT := 3.0
const ZOOM_STEP := 0.4
#endregion

## Zoom and pan the camera
func _input(event: InputEvent) -> void:
	# Zoom in and out with the mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			# Zoom must be pixel perfect
			zoom += Vector2(ZOOM_STEP, ZOOM_STEP)
			if zoom.x > MAX_ZOOM_OUT:
				zoom = Vector2(MAX_ZOOM_OUT, MAX_ZOOM_OUT)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom -= Vector2(ZOOM_STEP, ZOOM_STEP)
			if zoom.x < MAX_ZOOM_IN:
				zoom = Vector2(MAX_ZOOM_IN, MAX_ZOOM_IN)

	# Pan the camera with right mouse button
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		position -= event.relative / zoom * 2
