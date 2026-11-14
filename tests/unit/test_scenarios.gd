extends GutTest
## Plays every scenario that has a recorded transcript and compares.
## To record or update a transcript after a deliberate change:
##   godot --headless --path . --script res://tests/play_scenario.gd -- tests/scenarios/NAME.txt \
##       > tests/scenarios/NAME.expected.txt
## and review the difference in Git before committing.

const DIR := "res://tests/scenarios/"


func test_recorded_scenarios() -> void:
	var checked := 0
	for f in DirAccess.get_files_at(DIR):
		if not f.ends_with(".txt") or f.ends_with(".expected.txt"):
			continue
		var expected_path := DIR + f.get_basename() + ".expected.txt"
		if not FileAccess.file_exists(expected_path):
			continue
		var actual := ScenarioPlayer.play(FileAccess.get_file_as_string(DIR + f)).strip_edges()
		var expected := FileAccess.get_file_as_string(expected_path).strip_edges()
		if actual != expected:
			var a := actual.split("\n")
			var e := expected.split("\n")
			for i in maxi(a.size(), e.size()):
				var la := a[i] if i < a.size() else "<end>"
				var le := e[i] if i < e.size() else "<end>"
				if la != le:
					fail_test("%s differs at line %d:\n  expected: %s\n  actual:   %s" % [f, i + 1, le, la])
					break
		checked += 1
	assert_gt(checked, 0, "at least one recorded scenario")
