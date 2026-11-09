extends "res://tests/case.gd"
## Golden-value and oracle tests for sim/pcg32.gd (ADR-0020, "Randomness").
##
## RandomNumberGenerator is used here only as an oracle for the engine's PCG32
## stream; sim/ must never use it. The literal golden values below come from
## ADR-0020 and guard the stream even if a future engine changes its generator.

const GOLDEN_SEED: int = 20261104
const GOLDEN_FIRST: Array[int] = [437216612, 3904786994, 1372772354, 1922794527, 809608769]
# Seeds are uint64 in the engine and int64 in GDScript, so the negative seeds
# check the bit reinterpretation; -6398989897141750821 is the engine's
# DEFAULT_SEED 12047754176567800795 read as int64.
const ORACLE_SEEDS: Array[int] = [0, 1, 20261104, -1, -9223372036854775808, 9223372036854775807, -6398989897141750821]
const ORACLE_DRAWS: int = 20000


func test_first_values_match_adr_0020_golden_values() -> bool:
	var rng: Pcg32 = Pcg32.new(GOLDEN_SEED)
	for i: int in GOLDEN_FIRST.size():
		check_eq(rng.next_u32(), GOLDEN_FIRST[i], "draw %d with seed %d" % [i, GOLDEN_SEED])
	return true


func test_million_draws_match_adr_0020_hash_prefix() -> bool:
	# ADR-0020 gives the prefix 48185fb7ca681d2f but not the encoding. It was
	# recovered on 2026-11-09 by trying encodings of the engine's stream: the
	# draws stored in a PackedInt64Array and hashed via to_byte_array(), so each
	# value is eight little-endian bytes. A 64-bit prefix match rules out chance.
	var rng: Pcg32 = Pcg32.new(GOLDEN_SEED)
	var draws: PackedInt64Array = PackedInt64Array()
	draws.resize(1000000)
	for i: int in draws.size():
		draws[i] = rng.next_u32()
	var context: HashingContext = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(draws.to_byte_array())
	check_eq(context.finish().hex_encode().substr(0, 16), "48185fb7ca681d2f", "SHA-256 prefix of 1,000,000 draws")
	return true


func test_stream_matches_engine_randi_for_several_seeds() -> bool:
	for run_seed: int in ORACLE_SEEDS:
		var oracle: RandomNumberGenerator = RandomNumberGenerator.new()
		oracle.seed = run_seed
		var rng: Pcg32 = Pcg32.new(run_seed)
		check_eq(rng.get_state(), oracle.state, "state after seeding with %d" % run_seed)
		var mismatches: int = 0
		for i: int in ORACLE_DRAWS:
			if rng.next_u32() != oracle.randi():
				mismatches += 1
		check_eq(mismatches, 0, "mismatched draws over %d with seed %d" % [ORACLE_DRAWS, run_seed])
		check_eq(rng.get_state(), oracle.state, "state after %d draws with seed %d" % [ORACLE_DRAWS, run_seed])
	return true


func test_draws_are_ints_in_u32_range() -> bool:
	var rng: Pcg32 = Pcg32.new(GOLDEN_SEED)
	var out_of_range: int = 0
	for i: int in ORACLE_DRAWS:
		var value: Variant = rng.next_u32()
		if typeof(value) != TYPE_INT or value < 0 or value > 0xFFFFFFFF:
			out_of_range += 1
	check_eq(out_of_range, 0, "draws outside [0, 2^32)")
	return true


func test_next_below_matches_engine_bounded_draw() -> bool:
	# randi_range(from, from + bound - 1) is pcg32_boundedrand_r(bound) + from
	# in Godot 4.7.2, including its rejection of draws below
	# (2^32 - bound) % bound. randi_range takes C++ int arguments, so bounds
	# above 2^31 start from -2^31 to stay inside int32.
	var bounds: Array[int] = [1, 2, 3, 6, 10, 100, 10000, 2147483648, 2147483649, 0xFFFFFFFF, 0x100000000]
	for bound: int in bounds:
		var from: int = -2147483648 if bound > 2147483648 else 0
		var oracle: RandomNumberGenerator = RandomNumberGenerator.new()
		oracle.seed = GOLDEN_SEED
		var rng: Pcg32 = Pcg32.new(GOLDEN_SEED)
		var mismatches: int = 0
		var out_of_range: int = 0
		for i: int in ORACLE_DRAWS:
			var got: int = rng.next_below(bound)
			if got < 0 or got >= bound:
				out_of_range += 1
			if got + from != oracle.randi_range(from, from + bound - 1):
				mismatches += 1
		check_eq(out_of_range, 0, "next_below(%d) outside [0, bound)" % bound)
		check_eq(mismatches, 0, "next_below(%d) against randi_range" % bound)
		if bound == 1:
			# randi_range(from, from) returns early without drawing, while
			# pcg32_boundedrand_r(1) and next_below(1) consume one draw each.
			check(rng.get_state() != oracle.state, "next_below(1) consumes a draw that randi_range(x, x) does not")
		else:
			check_eq(rng.get_state(), oracle.state, "state after next_below(%d)" % bound)
	return true


func test_range_inclusive_matches_engine_randi_range() -> bool:
	var ranges: Array[Array] = [[-5, 5], [5, -5], [7, 7], [0, 1], [-2147483648, 2147483646], [-2147483648, 2147483647], [-10000, 0]]
	for pair: Array in ranges:
		var from: int = pair[0]
		var to: int = pair[1]
		var oracle: RandomNumberGenerator = RandomNumberGenerator.new()
		oracle.seed = GOLDEN_SEED
		var rng: Pcg32 = Pcg32.new(GOLDEN_SEED)
		var mismatches: int = 0
		for i: int in ORACLE_DRAWS:
			if rng.range_inclusive(from, to) != oracle.randi_range(from, to):
				mismatches += 1
		check_eq(mismatches, 0, "range_inclusive(%d, %d) against randi_range" % [from, to])
		check_eq(rng.get_state(), oracle.state, "state after range_inclusive(%d, %d)" % [from, to])
	return true


func test_pick_weighted_is_integer_and_follows_weights() -> bool:
	var weights: PackedInt64Array = PackedInt64Array([0, 3, 0, 1])
	var rng: Pcg32 = Pcg32.new(GOLDEN_SEED)
	var counts: Array[int] = [0, 0, 0, 0]
	for i: int in 40000:
		counts[rng.pick_weighted(weights)] += 1
	check_eq(counts[0], 0, "a zero weight is never picked")
	check_eq(counts[2], 0, "a zero weight is never picked")
	check_eq(counts[1] + counts[3], 40000, "every pick is a valid index")
	# Expected 30000 and 10000; the bound is about seven standard deviations.
	check(absi(counts[1] - 30000) < 600, "index 1 picked about 3/4 of the time, got %d" % counts[1])
	# The pick is next_below(total) walked over the weights, so it replays
	# exactly from the bounded draw.
	var a: Pcg32 = Pcg32.new(GOLDEN_SEED)
	var b: Pcg32 = Pcg32.new(GOLDEN_SEED)
	var expected: int = 0
	var roll: int = b.next_below(4)
	if roll >= 3:
		expected = 3
	else:
		expected = 1
	check_eq(a.pick_weighted(weights), expected, "first pick follows next_below(total)")
	return true


func test_same_seed_replays_and_state_round_trips() -> bool:
	var a: Pcg32 = Pcg32.new(GOLDEN_SEED)
	for i: int in 1000:
		a.next_u32()
	var b: Pcg32 = Pcg32.new(0)
	b.set_state(a.get_state())
	b.set_inc(a.get_inc())
	var mismatches: int = 0
	for i: int in 1000:
		if a.next_u32() != b.next_u32():
			mismatches += 1
	check_eq(mismatches, 0, "a generator restored from state and inc continues the stream")
	return true
