class_name RealityShiftBehavior
extends AbilityBehavior
## Reality Shift: swaps the zone of the Shift Anchor the player stands in.

func can_activate() -> bool:
	if not ShiftManager.can_shift():
		if ShiftManager.current_anchor() == null:
			EventBus.toast_requested.emit("TOAST_NO_ANCHOR", "info")
		return false
	return true

func activate() -> void:
	ShiftManager.shift_at_anchor()
