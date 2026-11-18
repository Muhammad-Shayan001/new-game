class_name Log
extends RefCounted
## Tiny logging helper. Every message carries a tag naming the system.
## Convention: Log.error for broken data or failed operations, Log.warn for recoverable problems.

static var verbose: bool = false
static var errors_seen: int = 0

static func info(tag: String, msg: String) -> void:
	if verbose:
		print("[%s] %s" % [tag, msg])

static func warn(tag: String, msg: String) -> void:
	push_warning("[%s] %s" % [tag, msg])

static func error(tag: String, msg: String) -> void:
	errors_seen += 1
	push_error("[%s] %s" % [tag, msg])
