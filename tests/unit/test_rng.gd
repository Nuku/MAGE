extends GutTest
## The generator must be seedable, repeatable and roughly uniform.

func test_seed_gives_nonzero_state() -> void:
	var r := Rng.new(42)
	assert_ne(r.get_state(), [0, 0, 0, 0])

func test_same_seed_same_sequence() -> void:
	var a := Rng.new(5)
	var b := Rng.new(5)
	for i in 50:
		assert_eq(a.range_int(1, 100), b.range_int(1, 100))

func test_different_seeds_differ() -> void:
	var a := Rng.new(1)
	var b := Rng.new(2)
	var same := 0
	for i in 50:
		if a.range_int(1, 1000) == b.range_int(1, 1000):
			same += 1
	assert_lt(same, 5)

func test_range_is_inclusive_and_uniform() -> void:
	var r := Rng.new(9)
	var counts := [0, 0, 0, 0, 0, 0]
	for i in 6000:
		counts[r.range_int(1, 6) - 1] += 1
	for c in counts:
		assert_between(c, 850, 1150)

func test_state_round_trip() -> void:
	var r := Rng.new(3)
	r.range_int(1, 10)
	var saved := r.get_state()
	var expected := r.range_int(1, 1000)
	var other := Rng.new(99)
	other.set_state(saved)
	assert_eq(other.range_int(1, 1000), expected)
