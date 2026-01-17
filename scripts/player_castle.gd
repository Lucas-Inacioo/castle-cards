extends Node2D

#region Children Nodes
@export var hover_timer: Timer
@export var castle_stats_popup: PanelContainer
#endregion

func _ready() -> void:
  hover_timer.connect("timeout", Callable(self, "on_hover_timeout"))

func mouse_entered_hover() -> void:
  hover_timer.start()

func mouse_exited_hover() -> void:
  hover_timer.stop()
  castle_stats_popup.visible = false

func on_hover_timeout() -> void:
  castle_stats_popup.visible = true
