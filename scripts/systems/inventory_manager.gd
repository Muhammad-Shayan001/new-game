extends Node
## Inventory items, clues and clue-linking (Deductions). Data lives in GameState.

func add_item(item_id: String, count: int = 1) -> bool:
	var def := DataRegistry.get_item(item_id)
	if def == null:
		GameLog.error("Inventory", "unknown item '%s'" % item_id)
		return false
	var have: int = GameState.inventory.get(item_id, 0)
	var limit := def.max_stack if def.stackable else 1
	var added := clampi(count, 0, limit - have)
	if added <= 0:
		return false
	GameState.inventory[item_id] = have + added
	EventBus.item_added.emit(item_id, added)
	return true

func remove_item(item_id: String, count: int = 1) -> bool:
	var have: int = GameState.inventory.get(item_id, 0)
	if count < 1 or have < count:
		return false
	if have == count:
		GameState.inventory.erase(item_id)
	else:
		GameState.inventory[item_id] = have - count
	EventBus.item_removed.emit(item_id, count)
	return true

func count_of(item_id: String) -> int:
	return GameState.inventory.get(item_id, 0)

func add_clue(clue_id: String) -> bool:
	if not IdRules.is_valid("clue", clue_id):
		GameLog.error("Inventory", "bad clue id '%s'" % clue_id)
		return false
	if not GameState.add_clue(clue_id):
		return false
	EventBus.clue_added.emit(clue_id)
	EventBus.toast_requested.emit("TOAST_CLUE_ADDED", "info")
	return true

## Journal "Link": combines two clues. Returns the deduction id or "" when they do not fit.
func link_clues(clue_a: String, clue_b: String) -> String:
	if not (GameState.has_clue(clue_a) and GameState.has_clue(clue_b)):
		return ""
	for d in DataRegistry.all("deduction"):
		var deduction := d as DeductionDef
		var match_ab := deduction.clue_a == clue_a and deduction.clue_b == clue_b
		var match_ba := deduction.clue_a == clue_b and deduction.clue_b == clue_a
		if not (match_ab or match_ba):
			continue
		if deduction.id in GameState.deductions:
			return deduction.id
		GameState.deductions.append(deduction.id)
		for f in deduction.set_flags:
			GameState.set_flag(f, true)
		if deduction.result_clue != "":
			add_clue(deduction.result_clue)
		EventBus.deduction_made.emit(deduction.id)
		return deduction.id
	EventBus.toast_requested.emit("TOAST_CLUES_DONT_FIT", "info")   # gentle, never punishing
	return ""
