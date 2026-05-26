# res://scripts/ui/CustomDraw.gd
extends Control
class_name CustomDraw

# A callable that will be called during _draw().
# It should accept a single argument: this CustomDraw instance.
var draw_callable: Callable

func _draw() -> void:
	if draw_callable.is_valid():
		draw_callable.call(self)
