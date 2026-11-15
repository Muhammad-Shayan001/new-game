class_name OrderingRuntime
extends PuzzleRuntime
## ORDERING / Memory Reconstruction: the player submits a full arrangement at once.

func submit(value: Variant) -> Result:
	if value is Array and value.size() == def.solution.size():
		for i in value.size():
			if str(value[i]) != def.solution[i]:
				return Result.FAILED
		return Result.SOLVED
	return Result.FAILED
