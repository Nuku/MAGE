extends GutTest

class FakeGame:
	var values := {"player.libido": 60, "adam.talk_progress": "camp", "p.flag": true}
	var states := ["none", "himself", "camp", "future"]
	var asked: Array = []
	func value(path: String) -> Variant:
		return values.get(path, null)
	func state_index(_path: String, v: Variant) -> int:
		return states.find(str(v))
	func turns_since(_path: String) -> int:
		return 5
	func ask(node: Dictionary) -> bool:
		asked.append(node.op)
		return node.get("who", "") == "player"

func test_forms_compile() -> void:
	for c in ["player is male", "player is in heat", "player is in library", "quest q reached access",
			"pure_pool outcome is saved", "chance 1 in 3", "check perception vs 15", "player has feat iron_stomach",
			"player does not have feat x", "adam has had sex", "player has water_bottle 2", "adam lives at camp",
			"player cock is wyvern", "time is night", "filter noncon is allowed", "level anal is more",
			"since adam.last_workout > 2 turns", "adam.talk_progress is at least camp", "won by seduction",
			"(a.b or c.d) and not e.f", "player.libido > player.humanity", "score > 3"]:
		assert_false(Condition.compile(c).has("error"), c)

func test_in_heat_is_an_adjective() -> void:
	assert_eq(Condition.compile("player is in heat").op, "is")
	assert_eq(Condition.compile("player is in library").op, "is_at")

func test_unknown_form_is_error() -> void:
	assert_true(Condition.compile("player is very much male indeed !").has("error"))
	assert_true(Condition.compile("adam.x >").has("error"))

func test_evaluate_comparisons_and_order() -> void:
	var g := FakeGame.new()
	assert_true(Condition.evaluate(Condition.compile("player.libido > 49"), g))
	assert_false(Condition.evaluate(Condition.compile("player.libido < 49"), g))
	assert_true(Condition.evaluate(Condition.compile("adam.talk_progress is camp"), g))
	assert_true(Condition.evaluate(Condition.compile("adam.talk_progress is at least himself"), g))
	assert_false(Condition.evaluate(Condition.compile("adam.talk_progress is at least future"), g))
	assert_true(Condition.evaluate(Condition.compile("p.flag"), g))
	assert_true(Condition.evaluate(Condition.compile("since adam.x > 2 turns"), g))

func test_evaluate_logic_and_negation() -> void:
	var g := FakeGame.new()
	assert_true(Condition.evaluate(Condition.compile("player is male and not adam is male"), g))
	assert_true(Condition.evaluate(Condition.compile("adam is male or player is male"), g))
	assert_true(Condition.evaluate(Condition.compile("adam is not male"), g))
