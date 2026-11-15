class_name GameLog
extends RefCounted
## Central logging. Never fail silently: every recoverable problem goes through
## warn() or error() so tests can count them and players get a stable log.

static var warning_count: int = 0
static var error_count: int = 0
static var last_error: String = ""

static func info(context: String, message: String) -> void:
	print("[%s] %s" % [context, message])

static func warn(context: String, message: String) -> void:
	warning_count += 1
	push_warning("[%s] %s" % [context, message])

static func error(context: String, message: String) -> void:
	error_count += 1
	last_error = "[%s] %s" % [context, message]
	push_error(last_error)

static func reset_counters() -> void:
	warning_count = 0
	error_count = 0
	last_error = ""
