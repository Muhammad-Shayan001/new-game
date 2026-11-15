class_name PatternRuntime
extends PuzzleRuntime
## PATTERN: the player enters symbols one at a time; a wrong symbol resets the entry.

var _entered: Array[String] = []

func submit(value: Variant) -> Result:
	_entered.append(str(value))
	for i in _entered.size():
		if _entered[i] != def.solution[i]:
			_entered.clear()
			return Result.FAILED
	if _entered.size() == def.solution.size():
		_entered.clear()
		return Result.SOLVED
	return Result.PROGRESS

func reset() -> void:
	_entered.clear()
