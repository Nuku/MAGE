class_name Rng
extends RefCounted
## Seedable random number generator (xoshiro128**).
##
## Uses only 32-bit values, shifts, xor and small multiplications, so the
## results are identical on every platform and Godot version and never rely
## on 64-bit overflow. The state is four 32-bit numbers and is saved with
## the game, so a game or a test continues with the same sequence.

const MASK := 0xFFFFFFFF

var s: Array[int] = [0, 0, 0, 0]


func _init(seed_value: int = 1) -> void:
	reseed(seed_value)


func reseed(seed_value: int) -> void:
	# Expand the seed with xorshift32 steps; never all zero.
	var x := (seed_value & MASK)
	if x == 0:
		x = 0x9E3779B9
	for k in 4:
		for _r in 3:
			x ^= (x << 13) & MASK
			x ^= x >> 17
			x ^= (x << 5) & MASK
		s[k] = x & MASK


static func _rotl(x: int, k: int) -> int:
	return ((x << k) | (x >> (32 - k))) & MASK


## Next 32-bit unsigned value.
func next_u32() -> int:
	var result := (_rotl((s[1] * 5) & MASK, 7) * 9) & MASK
	var t := (s[1] << 9) & MASK
	s[2] ^= s[0]
	s[3] ^= s[1]
	s[1] ^= s[2]
	s[0] ^= s[3]
	s[2] ^= t
	s[3] = _rotl(s[3], 11)
	return result


## Random integer from lo to hi, both included.
func range_int(lo: int, hi: int) -> int:
	if hi < lo:
		var tmp := lo
		lo = hi
		hi = tmp
	var span := hi - lo + 1
	# Rejection sampling avoids bias.
	var limit := (0x100000000 / span) * span
	var v := next_u32()
	while v >= limit:
		v = next_u32()
	return lo + v % span


## True with probability n in d.
func chance(n: int, d: int) -> bool:
	if d <= 0:
		return false
	return range_int(1, d) <= n


func get_state() -> Array:
	return s.duplicate()


func set_state(state: Array) -> void:
	for k in 4:
		s[k] = int(state[k]) & MASK
