class_name FadeOverlay
extends CanvasLayer
## Full-screen black fade used by SceneRouter. fade_to() can be awaited.

@onready var _rect: ColorRect = $Rect

func fade_to(alpha: float, duration: float) -> void:
	if duration <= 0.0 or not is_inside_tree():
		_rect.modulate.a = alpha
		return
	var tween := create_tween()
	tween.tween_property(_rect, "modulate:a", alpha, duration)
	await tween.finished
