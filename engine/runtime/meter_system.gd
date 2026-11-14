class_name MeterSystem
extends RefCounted
## Meters: a number with stages, such as alcohol. Each stage is a condition
## whose `while active` effects apply while the meter is in that stage. On
## every update the current stage is taken off and put back on, as in the
## original's alcohol rules (Core Mechanics/AlcoholMechanics.i7x): the stage
## condition's `enters` text plays when the stage is new, `still` when it is
## the stage that was just taken off, then its `each update` scene. A meter
## at or above its `limit` plays `at limit` instead. Meters decay by `decay`
## each turn while above zero; reaching zero forgets the previous stage.


## The meter (if any) that owns a value path, such as "player.alcohol".
static func owner_of(game, path: String) -> String:
	for id in game.content.all_of("meter"):
		if game.content.typed_value("meter", id, "value") == path:
			return id
	return ""


static func value_of(game, id: String) -> int:
	var v = game.value(game.content.typed_value("meter", id, "value"))
	return int(v) if v != null else 0


## Stages as [[threshold, condition id]], highest threshold first.
static func stages(game, id: String) -> Array:
	var out: Array = []
	var d: FscParser.Definition = game.content.get_def("meter", id)
	if d == null or not d.fields.has("stages"):
		return out
	for line in d.fields.stages.children:
		if not line.is_blank() and ":" in line.text:
			var pair: PackedStringArray = line.text.split(":", true, 1)
			out.append([int(pair[0].strip_edges()), pair[1].strip_edges()])
	out.sort_custom(func(a, b): return a[0] > b[0])
	return out


static func stage_for(game, id: String, amount: int) -> String:
	for s in stages(game, id):
		if amount >= int(s[0]):
			return str(s[1])
	return ""


## Re-applies the meter's stage after its value changed.
static func update(game, id: String) -> void:
	var path: String = game.content.typed_value("meter", id, "value")
	var amount := value_of(game, id)
	if amount < 0:
		game.state.values[path] = 0
		amount = 0
	var key := "meter.%s.stage" % id
	var previous := ""
	for s in stages(game, id):
		if game.state.conditions.has(s[1]):
			previous = str(s[1])
			game.end_condition(s[1])
	if previous != "":
		game.state.values[key] = previous
	var limit := int(game.content.typed_value("meter", id, "limit", "0"))
	if limit > 0 and amount >= limit:
		_play(game, "meter:%s#at limit" % id)
		return
	var stage := stage_for(game, id, amount)
	if stage == "":
		return
	game.start_condition(stage, 1 << 30, true)
	var field := "still" if str(game.state.values.get(key, "")) == stage else "enters"
	_play(game, "condition:%s#%s" % [stage, field])
	_play(game, "condition:%s#each update" % stage)


## Each turn: meters above zero go down by their decay.
static func tick(game) -> void:
	for id in game.content.all_of("meter"):
		var decay := int(game.content.typed_value("meter", id, "decay", "0"))
		var amount := value_of(game, id)
		if decay <= 0 or amount <= 0:
			continue
		var path: String = game.content.typed_value("meter", id, "value")
		game.state.values[path] = maxi(0, amount - decay)
		update(game, id)
		if value_of(game, id) == 0:
			game.state.values.erase("meter.%s.stage" % id)


static func _play(game, pid: String) -> void:
	if game.content.program(pid) != null:
		game.runner.play_now(pid)
