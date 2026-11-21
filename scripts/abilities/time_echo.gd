class_name TimeEchoBehavior
extends AbilityBehavior
## Time Echo: replay a past event at an Echo Site, or record a ghost in a record zone.

func can_activate() -> bool:
	return TimeEchoManager.can_use()

func activate() -> void:
	TimeEchoManager.use()
