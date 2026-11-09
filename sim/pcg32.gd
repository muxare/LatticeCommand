class_name Pcg32
extends RefCounted
## The simulation's own random number generator (ADR-0020, "Randomness").
##
## PCG32 (XSH RR) as in M.E. O'Neill's pcg-c-basic, seeded the way Godot
## 4.7.2's engine generator class seeds it, so that Pcg32.new(s).next_u32()
## gives the same stream as that class's 32-bit draw after setting its seed to
## s; tests/test_pcg32.gd uses the engine class as an oracle. Comments here
## avoid the engine names because the drift greps in ADR-0006 and ADR-0020 do
## not skip comments. The engine's increment is PCG_DEFAULT_INC_64; seeding sets state to 0 and
## inc to (initseq << 1) | 1, steps once, adds the seed to the state and steps
## again (core/math/random_pcg.h, thirdparty/misc/pcg.cpp).
##
## Everything is integer arithmetic on GDScript's 64-bit int, which holds the
## generator's uint64 state as the same bits. Multiplication and addition wrap
## modulo 2^64, which the golden-value test in tests/test_pcg32.gd guards
## because the documentation does not promise it. Right shifts in GDScript are
## arithmetic, so every shift of the state masks off the sign extension.

const MULTIPLIER: int = 6364136223846793005
const DEFAULT_INC_64: int = 1442695040888963407
const MASK_32: int = 0xFFFFFFFF
const TWO_POW_32: int = 0x100000000
const MAX_INT: int = 9223372036854775807

var _state: int = 0
var _inc: int = 0


func _init(run_seed: int) -> void:
	reseed(run_seed)


## Reseeds exactly as setting the engine generator's seed property does. The seed is
## a uint64 in the engine, so a negative int is read as the same 64 bits.
func reseed(run_seed: int) -> void:
	_state = 0
	_inc = (DEFAULT_INC_64 << 1) | 1
	next_u32()
	_state += run_seed
	next_u32()


## Returns the next 32-bit draw as an int in [0, 2^32).
func next_u32() -> int:
	var old: int = _state
	_state = old * MULTIPLIER + _inc
	var xorshifted: int = ((((old >> 18) & 0x3FFFFFFFFFFF) ^ old) >> 27) & MASK_32
	var rot: int = (old >> 59) & 31
	return ((xorshifted >> rot) | (xorshifted << ((32 - rot) & 31))) & MASK_32


## Returns an unbiased int in [0, bound) for 1 <= bound <= 2^32, by the
## rejection method of pcg32_boundedrand_r, which the engine's randi_range uses.
## Any other bound logs an error, returns 0 and consumes no draw. Invalid
## input is checked explicitly rather than with an assertion, because release
## builds strip assertions and would then draw where debug builds do not, which
## would break replay between builds (ADR-0006).
func next_below(bound: int) -> int:
	if bound < 1 or bound > TWO_POW_32:
		push_error("Pcg32.next_below: bound %d is outside [1, 2^32]" % bound)
		return 0
	var threshold: int = (TWO_POW_32 - bound) % bound
	while true:
		var r: int = next_u32()
		if r >= threshold:
			return r % bound
	return 0


## Returns an int in the closed range between from and to, in either order,
## matching the engine generator's inclusive integer range for 32-bit arguments.
## A span of more than 2^32 values logs an error, returns the lower end and
## consumes no draw. Like the engine, range_inclusive(x, x) returns x without
## drawing, so changing a content range to a single value shifts every later
## draw in the run.
func range_inclusive(from: int, to: int) -> int:
	if from == to:
		return from
	var low: int = mini(from, to)
	var high: int = maxi(from, to)
	# high - low can overflow int64 only when low is negative; this test of the
	# span cannot overflow itself.
	if (low < 0 and high > MAX_INT + low) or high - low >= TWO_POW_32:
		push_error("Pcg32.range_inclusive: span from %d to %d exceeds 2^32 values" % [low, high])
		return low
	return low + next_below(high - low + 1)


## Returns an index into weights with probability weight / total, using one
## bounded draw over the integer total. Weights must be non-negative, at
## least one must be positive, and the total must not exceed 2^32; otherwise
## it logs an error, returns -1 and consumes no draw.
func pick_weighted(weights: PackedInt64Array) -> int:
	var total: int = 0
	for weight: int in weights:
		# Each weight and the running total stay at most 2^32, so the sum
		# cannot overflow.
		if weight < 0 or weight > TWO_POW_32 or total + weight > TWO_POW_32:
			push_error("Pcg32.pick_weighted: weights must be non-negative and total at most 2^32")
			return -1
		total += weight
	if total < 1:
		push_error("Pcg32.pick_weighted: weights are empty or all zero")
		return -1
	var roll: int = next_below(total)
	for i: int in weights.size():
		roll -= weights[i]
		if roll < 0:
			return i
	return -1


## Returns the 64-bit state as the same bits that the engine generator's state
## reports, for saving and restoring a stream.
func get_state() -> int:
	return _state


func set_state(state: int) -> void:
	_state = state


func get_inc() -> int:
	return _inc


func set_inc(inc: int) -> void:
	_inc = inc | 1
