extends Camera2D

#region Camera Constants
const MAX_ZOOM_IN := 0.5
const MAX_ZOOM_OUT := 3.0
const ZOOM_STEP := 0.1
#endregion

## Zoom and pan the camera
func _input(event: InputEvent) -> void:
	# Zoom in and out with the mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom.x = clamp((1 - ZOOM_STEP) * zoom.x, MAX_ZOOM_IN, MAX_ZOOM_OUT)
			zoom.y = clamp((1 - ZOOM_STEP) * zoom.y, MAX_ZOOM_IN, MAX_ZOOM_OUT)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom.x = clamp((1 + ZOOM_STEP) * zoom.x, MAX_ZOOM_IN, MAX_ZOOM_OUT)
			zoom.y = clamp((1 + ZOOM_STEP) * zoom.y, MAX_ZOOM_IN, MAX_ZOOM_OUT)

	# Pan the camera with right mouse button
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		position -= event.relative / zoom * 2
