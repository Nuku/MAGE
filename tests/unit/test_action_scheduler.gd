extends GutTest

var game: Game


func before_each() -> void:
	var db := ContentDB.new()
	db.load_folders(["res://tests/packs"])
	game = Game.new(db, 42)
	game.start("shelter")
	game.take_output()


func after_each() -> void:
	game.dispose()


func test_action_clock_is_separate_from_survival_and_read_only_views() -> void:
	game.apply(Effect.compile("schedule timer.first after 2 actions"))
	game.pass_turn()
	game.runner.show_location()
	game.inventory_list()
	game.status_snapshot()
	assert_eq(game.state.actions, 0)
	game.runner.act("go", "up")
	assert_eq(game.state.actions, 1)
	assert_eq(game.state.turn, 1)
	assert_eq(game.runner.status, "idle")
	game.runner.act("go", "down")
	assert_eq(game.state.actions, 2)
	assert_eq(game.runner.status, "continue")
	assert_true(game.state.scheduled.is_empty(), "due timer is consumed before the scene pauses")


func test_timer_and_paused_scene_survive_json_in_a_fresh_game() -> void:
	game.apply(Effect.compile("schedule timer.first after 2 actions"))
	game.runner.act("go", "up")
	var other := Game.new(game.content, 7)
	assert_true(other.load_dict(JSON.parse_string(JSON.stringify(game.save_dict()))))
	assert_eq(other.state.actions, 1)
	other.runner.act("go", "down")
	assert_eq(other.runner.status, "continue")
	assert_true(game.load_dict(JSON.parse_string(JSON.stringify(other.save_dict()))))
	game.runner.proceed()
	assert_eq(game.state.actions, 2, "continuing the timer scene is not another action")
	assert_eq(game.state.scheduled.size(), 1)
	game.runner.act("go", "up")
	assert_string_contains(str(game.take_output()), "Second scheduled scene.")
	assert_eq(game.value("player.score"), 3, "one discovery plus exactly one timer reward")
	assert_eq(game.state.actions, 3)
	other.dispose()


func test_same_deadline_runs_in_scheduling_order() -> void:
	game.apply(Effect.compile("schedule timer.first after 1 action"))
	game.apply(Effect.compile("schedule timer.second after 1 action"))
	game.runner.act("go", "up")
	var first := str(game.take_output())
	assert_string_contains(first, "First scheduled scene.")
	assert_false(first.contains("Second scheduled scene."))
	game.runner.proceed()
	var rest := str(game.take_output())
	assert_lt(rest.find("First scene finished."), rest.find("Second scheduled scene."))
	assert_eq(game.state.actions, 1)


func test_conversation_completes_once_after_all_its_choices() -> void:
	game.apply(Effect.compile("schedule timer.second after 1 action"))
	game.runner.act("talk", "mira")
	assert_eq(game.state.actions, 0)
	assert_true(game.state.action_pending)
	game.runner.choose(0)
	game.runner.proceed()
	assert_eq(game.state.actions, 0)
	# Leave is appended after the currently available topics.
	game.runner.choose(game.runner.pending.size() - 1)
	assert_eq(game.state.actions, 1)
	assert_false(game.state.action_pending)
	assert_string_contains(str(game.take_output()), "Second scheduled scene.")


func test_failed_gameplay_attempt_counts_but_unknown_actions_do_not() -> void:
	game.apply(Effect.compile("schedule timer.second after 1 action"))
	assert_false(game.runner.act("not_an_action"))
	assert_eq(game.state.actions, 0)
	assert_false(game.runner.act("go", "west"))
	assert_eq(game.state.actions, 1)
	assert_string_contains(str(game.take_output()), "Second scheduled scene.")


func test_missing_saved_timer_scene_is_rejected_before_replacing_state() -> void:
	var saved := game.save_dict().duplicate(true)
	saved.state.scheduled = [{"scene": "deleted.scene", "due": 1}]
	var before := game.state.to_dict().duplicate(true)
	assert_false(game.load_dict(saved))
	assert_eq(game.state.to_dict(), before)
	assert_string_contains(game.warnings[-1], "not available")


func test_turn_hooks_do_not_finish_a_rest_action_between_its_two_turns() -> void:
	game.start_condition("timer_pulse", 3, true)
	game.apply(Effect.compile("schedule timer.second after 1 action"))
	game.take_output()
	game.runner.act("rest")
	var output := str(game.take_output())
	assert_gt(output.find("Second scheduled scene."), output.rfind("The timer pulses."))
	assert_eq(game.state.turn, 2)
	assert_eq(game.state.actions, 1)
	assert_false(game.state.action_pending)
