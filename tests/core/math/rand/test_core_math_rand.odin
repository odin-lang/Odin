#+build !netbsd
package test_core_math_rand

import "base:runtime"
import "core:math"
import "core:math/rand"
import "core:testing"

Generator :: struct {
	name:   string,
	gen:    rand.Generator,
	biased: bool,
}

// Disable on NetBSD due to Illegal Instruction on CI, even with `microarch:native`
// `@(test, disable="...")` still runs the test.

@(test)
test_prngs :: proc(t: ^testing.T) {
	gens := []Generator {
		{
			"default",
			rand.default_random_generator(),
			false,
		},
		{
			"pcg64",
			rand.pcg_random_generator(), // Deprecated
			true,
		},
		{
			"xoshiro**",
			rand.xoshiro256_random_generator(),
			false,
		},
	}
	for gen in gens {
		rand_determinism(t, gen)
		if !gen.biased {
			rand_issue_5881(t, gen)
		}
	}
}

@(private = "file")
rand_determinism :: proc(t: ^testing.T, rng: Generator) {
	context.random_generator = rng.gen
	rand.reset(13)
	first_value := rand.int127()
	rand.reset(13)
	second_value := rand.int127()

	testing.expectf(t, first_value == second_value, "rng '%s' is non-deterministic.", rng.name)
}

@(test)
test_default_rand_determinism_user_set :: proc(t: ^testing.T) {
	rng_state_1 := rand.create(13)
	rng_state_2 := rand.create(13)

	rng_1 := rand.default_random_generator(&rng_state_1)
	rng_2 := rand.default_random_generator(&rng_state_2)

	first_value, second_value: i128
	{
		context.random_generator = rng_1
		first_value = rand.int127()
	}
	{
		context.random_generator = rng_2
		second_value = rand.int127()
	}

	testing.expect(t, first_value == second_value, "User-set default random number generator is non-deterministic.")
}

@(private = "file")
rand_issue_5881 :: proc(t:^testing.T, rng: Generator) {
	// Tests issue #5881 https://github.com/odin-lang/Odin/issues/5881

	// Bit balance and sign uniformity (modest samples to keep CI fast)
	expect_u64_bit_balance(t, rng, 200_000)
	expect_quaternion_sign_uniformity(t, rng, 200_000)
}

@(test)
test_issue_5978 :: proc(t:^testing.T) {
	// Tests issue #5978 https://github.com/odin-lang/Odin/issues/5978

	s := bit_set[1 ..= 5]{1, 5}

	cases := []struct {
		seed: u64,
		expected: int,
	}{ {13, 1}, {27, 5} }

	for c in cases {
		rand.reset(c.seed)
		i, _ := rand.choice_bit_set(s)
		testing.expectf(t, i == c.expected, "choice_bit_set returned %v with seed %v, expected %v", i, c.seed, c.expected)
	}
}

// Helper: compute chi-square statistic for counts vs equal-expected across k bins
@(private = "file")
chi_square_equal :: proc(counts: []int) -> f64 {
	n := 0
	for c in counts {
		n += c
	}
	if n == 0 {
		return 0
	}
	k := len(counts)
	exp := f64(n) / f64(k)
	stat := f64(0)
	for c in counts {
		d := f64(c) - exp
		stat += (d * d) / exp
	}
	return stat
}

// Helper: check bit balance on u64 across many samples
@(private = "file")
expect_u64_bit_balance :: proc(t: ^testing.T, rng: Generator, samples: int, sigma_k: f64 = 6) {
	rand.reset(t.seed, rng.gen)

	ones: [64]int
	for i := 0; i < samples; i += 1 {
		v := rand.uint64(rng.gen)
		for b := 0; b < 64; b += 1 {
			ones[b] += int((v >> u64(b)) & 1)
		}
	}
	mu := f64(samples) * 0.5
	sigma := math.sqrt(f64(samples) * 0.25)
	limit := sigma_k * sigma
	for b := 0; b < 64; b += 1 {
		diff := math.abs(f64(ones[b]) - mu)
		if diff > limit {
			testing.expectf(t, false, "rng '%s': u64 bit %d imbalance: ones=%d samples=%d diff=%.1f limit=%.1f", rng.name, b, ones[b], samples, diff, limit)
			return
		}
	}
}

// Helper: Uniformity sanity via 4D sign orthant chi-square with modest sample size.
@(private = "file")
expect_quaternion_sign_uniformity :: proc(t: ^testing.T, rng: Generator, iterations: int) {
	counts: [16]int
	for _ in 0..<iterations {
		// Map 4D signs to 0..15 index
		x := rand.float64_range(-10, 10, rng.gen)
		y := rand.float64_range(-10, 10, rng.gen)
		z := rand.float64_range(-10, 10, rng.gen)
		w := rand.float64_range(-10, 10, rng.gen)
		idx := 0
		if x >= 0 { idx |= 1 }
		if y >= 0 { idx |= 2 }
		if z >= 0 { idx |= 4 }
		if w >= 0 { idx |= 8 }
		counts[idx] += 1
	}
	// df = 15. For a modest sample size, use a generous cutoff to reduce flakiness.
	// Chi-square critical values (df=15): p=0.001 -> ~37.7, p=0.0001 -> ~43.8
	// We accept < 55 as a conservative stability bound across platforms.
	chi := chi_square_equal(counts[:])
	testing.expectf(t, chi < 55.0, "rng '%s': 4D sign chi-square too high: %.3f (counts=%v)", rng.name, chi, counts)
}

@(private = "file")
Scripted :: struct {
	values: []u64,
	used:   int,
	sm:     u64,
}

@(private = "file")
scripted_proc :: proc(data: rawptr, mode: runtime.Random_Generator_Mode, p: []byte) {
	s := (^Scripted)(data)
	if mode != .Read {
		return
	}
	v: u64
	if s.used < len(s.values) {
		v = s.values[s.used]
	} else {
		s.sm += 0x9e3779b97f4a7c15
		z := s.sm
		z = (z ~ (z >> 30)) * 0xbf58476d1ce4e5b9
		z = (z ~ (z >> 27)) * 0x94d049bb133111eb
		v = z ~ (z >> 31)
	}
	s.used += 1
	for i := 0; i < len(p); i += 8 {
		runtime.mem_copy_non_overlapping(&p[i], &v, min(len(p) - i, 8))
	}
}

@(private = "file")
scripted :: proc(s: ^Scripted) -> rand.Generator {
	return {scripted_proc, s}
}

@(private = "file")
xoshiro :: proc(state: ^rand.Xoshiro256_Random_State, seed: u64) -> rand.Generator {
	gen := rand.xoshiro256_random_generator(state)
	rand.reset(seed, gen)
	return gen
}

@(test)
test_xoshiro256_vectors :: proc(t: ^testing.T) {
	cases := []struct {
		seed: u64,
		want: [4]u64,
	}{
		{0,        {0x99ec5f36cb75f2b4, 0xbf6e1f784956452a, 0x1a5f849d4933e6e0, 0x6aa594f1262d2d2c}},
		{1,        {0xb3f2af6d0fc710c5, 0x853b559647364cea, 0x92f89756082a4514, 0x642e1c7bc266a3a7}},
		{42,       {0x15780b2e0c2ec716, 0x6104d9866d113a7e, 0xae17533239e499a1, 0xecb8ad4703b360a1}},
		{max(u64), {0x8f5520d52a7ead08, 0xc476a018caa1802d, 0x81de31c0d260469e, 0xbf658d7e065f3c2f}},
	}
	for c in cases {
		state: rand.Xoshiro256_Random_State
		gen := xoshiro(&state, c.seed)
		for want, i in c.want {
			got := rand.uint64(gen)
			testing.expectf(t, got == want, "xoshiro256 seed %x output %v: expected %x, got %x", c.seed, i, want, got)
		}
	}

	state := rand.Xoshiro256_Random_State{s = {1, 2, 3, 4}}
	gen := rand.xoshiro256_random_generator(&state)
	for want in ([]u64{11520, 0, 1509978240, 1215971899390074240}) {
		testing.expect_value(t, rand.uint64(gen), want)
	}
}

@(test)
test_pcg_vectors :: proc(t: ^testing.T) {
	cases := []struct {
		seed: u64,
		want: [4]u64,
	}{
		{1,        {0x4b6ce3c55f577cc1, 0xba08a217f4570873, 0x129e5daa0e49fa97, 0xd3cd39cf85037b27}},
		{42,       {0xe6c607db23420574, 0xb06395c16eb6d1d1, 0x5ed54b1672e133c6, 0xceeec502b3cf5125}},
		{max(u64), {0xf9dd7f7580917e07, 0xfef151f77e45b63f, 0x6b9108409d8a574d, 0x5dd506e622aded7a}},
	}
	for c in cases {
		state: rand.PCG_Random_State
		gen := rand.pcg_random_generator(&state)
		rand.reset(c.seed, gen)
		for want, i in c.want {
			got := rand.uint64(gen)
			testing.expectf(t, got == want, "pcg seed %x output %v: expected %x, got %x", c.seed, i, want, got)
		}
	}
}

@(test)
test_read_lengths :: proc(t: ^testing.T) {
	outputs := [3]u64{0x15780b2e0c2ec716, 0x6104d9866d113a7e, 0xae17533239e499a1}
	stream: [24]u8
	for &b, i in stream {
		b = u8(outputs[i / 8] >> (8 * uint(i % 8)))
	}

	for n in 0..=24 {
		state: rand.Xoshiro256_Random_State
		gen := xoshiro(&state, 42)
		buf, want: [24]u8
		copy(want[:n], stream[:n])
		testing.expect_value(t, rand.read(buf[:n], gen), n)
		testing.expectf(t, buf == want, "read of %v bytes: expected %v, got %v", n, want[:n], buf[:n])
	}

	state: rand.Xoshiro256_Random_State
	gen := xoshiro(&state, 42)
	buf: [8]u8
	testing.expect_value(t, rand.read(buf[:4], gen), 4)
	testing.expect_value(t, rand.read(buf[4:], gen), 4)
	testing.expect_value(t, buf, [8]u8{stream[0], stream[1], stream[2], stream[3], stream[8], stream[9], stream[10], stream[11]})
}

@(test)
test_float_edges :: proc(t: ^testing.T) {
	cases := []struct {
		value:  u64,
		want64: f64,
		want32: f32,
	}{
		{0,         0,                 0},
		{max(u64),  1 - 1.0 / (1<<53), 1 - 1.0 / (1<<24)},
		{1 << 63,   0,                 0},
		{1 << 53,   0,                 0},
		{1 << 51,   0.25,              0},
		{1 << 24,   1.0 / (1<<29),     0},
		{1 << 22,   1.0 / (1<<31),     0.25},
	}
	for c in cases {
		s64 := Scripted{values = {c.value}}
		got64 := rand.float64(scripted(&s64))
		testing.expectf(t, got64 == c.want64 && s64.used == 1, "float64 with %x: expected %v, got %v", c.value, c.want64, got64)
		s32 := Scripted{values = {c.value}}
		got32 := rand.float32(scripted(&s32))
		testing.expectf(t, got32 == c.want32 && s32.used == 1, "float32 with %x: expected %v, got %v", c.value, c.want32, got32)
	}
}

@(test)
test_max_rejection :: proc(t: ^testing.T) {
	for n in ([]u64{3, 5, 10, 1000, 1<<31 - 1}) {
		limit := u64(1<<31) - u64(1<<31) % n - 1
		s := Scripted{values = {limit + 1, limit}}
		got := rand.int31_max(i32(n), scripted(&s))
		testing.expectf(t, u64(got) == limit % n && s.used == 2, "int31_max(%v): expected %v after 2 draws, got %v after %v", n, limit % n, got, s.used)
	}
	for n in ([]u64{3, 5, 10, 1000, 1<<63 - 1}) {
		limit := u64(1<<63) - u64(1<<63) % n - 1
		s := Scripted{values = {limit + 1, limit}}
		got := rand.int63_max(i64(n), scripted(&s))
		testing.expectf(t, u64(got) == limit % n && s.used == 2, "int63_max(%v): expected %v after 2 draws, got %v after %v", n, limit % n, got, s.used)
	}
	for n in ([]u128{3, 10, 1<<127 - 1}) {
		limit := u128(1<<127) - u128(1<<127) % n - 1
		over := limit + 1
		s := Scripted{values = {u64(over >> 64), u64(over), u64(limit >> 64), u64(limit)}}
		got := rand.int127_max(i128(n), scripted(&s))
		testing.expectf(t, u128(got) == limit % n && s.used == 4, "int127_max(%v): expected %v after 4 draws, got %v after %v", n, limit % n, got, s.used)
	}

	for n in ([]u64{3, 5, 10, 1000, u64(max(u32))}) {
		threshold := u64(1<<32) % n
		s := Scripted{values = {threshold - 1, threshold + 7}}
		got := rand.uint32_max(u32(n), scripted(&s))
		testing.expectf(t, u64(got) == (threshold + 7) % n && s.used == 2, "uint32_max(%v): expected %v after 2 draws, got %v after %v", n, (threshold + 7) % n, got, s.used)
	}
	for n in ([]u64{3, 5, 10, 1000, max(u64)}) {
		threshold := (max(u64) % n + 1) % n
		s := Scripted{values = {threshold - 1, threshold + 7}}
		got := rand.uint64_max(n, scripted(&s))
		testing.expectf(t, got == (threshold + 7) % n && s.used == 2, "uint64_max(%v): expected %v after 2 draws, got %v after %v", n, (threshold + 7) % n, got, s.used)
	}
	for n in ([]u128{3, 10, 1<<100 + 1, max(u128)}) {
		threshold := (max(u128) % n + 1) % n
		under := threshold - 1
		s := Scripted{values = {u64(under >> 64), u64(under), u64(threshold >> 64), u64(threshold)}}
		got := rand.uint128_max(n, scripted(&s))
		testing.expectf(t, got == threshold % n && s.used == 4, "uint128_max(%v): expected %v after 4 draws, got %v after %v", n, threshold % n, got, s.used)
	}

	pow2_31 := Scripted{values = {max(u64)}}
	testing.expect_value(t, rand.int31_max(8, scripted(&pow2_31)), 7)
	pow2_64 := Scripted{values = {max(u64)}}
	testing.expect_value(t, rand.uint64_max(1 << 40, scripted(&pow2_64)), 1<<40 - 1)

	for seed in u64(1)..=20 {
		a := Scripted{sm = seed}
		b := Scripted{sm = seed}
		c := Scripted{sm = seed}
		d := Scripted{sm = seed}
		when size_of(int) == size_of(i64) {
			testing.expect_value(t, rand.int_max(1000, scripted(&a)), int(rand.int63_max(1000, scripted(&b))))
			testing.expect_value(t, rand.uint_max(1000, scripted(&c)), uint(rand.uint64_max(1000, scripted(&d))))
		} else {
			testing.expect_value(t, rand.int_max(1000, scripted(&a)), int(rand.int31_max(1000, scripted(&b))))
			testing.expect_value(t, rand.uint_max(1000, scripted(&c)), uint(rand.uint32_max(1000, scripted(&d))))
		}
	}
}

@(test)
test_range_rejection :: proc(t: ^testing.T) {
	for c in ([][2]u32{{10, 13}, {5, 1005}, {0, max(u32)}, {1, max(u32)}}) {
		r := u64(c[1] - c[0])
		threshold := u64(1<<32) % r
		s := Scripted{values = {threshold - 1, threshold + 7}}
		got := rand.uint32_range(c[0], c[1], scripted(&s))
		want := u64(c[0]) + (threshold + 7) % r
		testing.expectf(t, u64(got) == want && s.used == 2, "uint32_range(%v, %v): expected %v after 2 draws, got %v after %v", c[0], c[1], want, got, s.used)
	}
	for c in ([][2]i32{{-5, 5}, {-3, 0}, {min(i32), max(i32)}, {min(i32), min(i32) + 3}, {max(i32) - 3, max(i32)}}) {
		r := u64(i64(c[1]) - i64(c[0]))
		threshold := u64(1<<32) % r
		s := Scripted{values = {threshold - 1, threshold + 7}}
		got := rand.int32_range(c[0], c[1], scripted(&s))
		want := i64(c[0]) + i64((threshold + 7) % r)
		testing.expectf(t, i64(got) == want && s.used == 2, "int32_range(%v, %v): expected %v after 2 draws, got %v after %v", c[0], c[1], want, got, s.used)
	}
	for c in ([][2]u64{{10, 13}, {5, 1005}, {0, max(u64)}, {1, max(u64)}}) {
		r := c[1] - c[0]
		threshold := (max(u64) % r + 1) % r
		s := Scripted{values = {threshold - 1, threshold + 7}}
		got := rand.uint64_range(c[0], c[1], scripted(&s))
		want := c[0] + (threshold + 7) % r
		testing.expectf(t, got == want && s.used == 2, "uint64_range(%v, %v): expected %v after 2 draws, got %v after %v", c[0], c[1], want, got, s.used)
	}
	for c in ([][2]i64{{-5, 5}, {-3, 0}, {min(i64), max(i64)}, {min(i64), min(i64) + 3}, {max(i64) - 3, max(i64)}}) {
		r := u64(i128(c[1]) - i128(c[0]))
		threshold := (max(u64) % r + 1) % r
		s := Scripted{values = {threshold - 1, threshold + 7}}
		got := rand.int64_range(c[0], c[1], scripted(&s))
		want := i128(c[0]) + i128((threshold + 7) % r)
		testing.expectf(t, i128(got) == want && s.used == 2, "int64_range(%v, %v): expected %v after 2 draws, got %v after %v", c[0], c[1], want, got, s.used)
	}
	for c in ([][2]i128{{-5, 5}, {-(1<<100), 1<<100 + 5}, {min(i128), max(i128)}}) {
		r := u128(c[1]) - u128(c[0])
		threshold := (max(u128) % r + 1) % r
		under := threshold - 1
		over := threshold + 7
		s := Scripted{values = {u64(under >> 64), u64(under), u64(over >> 64), u64(over)}}
		got := rand.int128_range(c[0], c[1], scripted(&s))
		want := c[0] + i128(over % r)
		testing.expectf(t, got == want && s.used == 4, "int128_range(%v, %v): expected %v after 4 draws, got %v after %v", c[0], c[1], want, got, s.used)

		us := Scripted{values = {u64(under >> 64), u64(under), u64(over >> 64), u64(over)}}
		ugot := rand.uint128_range(u128(c[0]) + (1<<127), u128(c[1]) + (1<<127), scripted(&us))
		uwant := u128(c[0]) + (1<<127) + over % r
		testing.expectf(t, ugot == uwant && us.used == 4, "uint128_range(%v, %v): expected %v after 4 draws, got %v after %v", u128(c[0]) + (1<<127), u128(c[1]) + (1<<127), uwant, ugot, us.used)
	}

	for seed in u64(1)..=20 {
		a := Scripted{sm = seed}
		b := Scripted{sm = seed}
		c := Scripted{sm = seed}
		d := Scripted{sm = seed}
		when size_of(int) == size_of(i64) {
			testing.expect_value(t, rand.int_range(-500, 500, scripted(&a)), int(rand.int64_range(-500, 500, scripted(&b))))
			testing.expect_value(t, rand.uint_range(7, 1007, scripted(&c)), uint(rand.uint64_range(7, 1007, scripted(&d))))
		} else {
			testing.expect_value(t, rand.int_range(-500, 500, scripted(&a)), int(rand.int32_range(-500, 500, scripted(&b))))
			testing.expect_value(t, rand.uint_range(7, 1007, scripted(&c)), uint(rand.uint32_range(7, 1007, scripted(&d))))
		}
	}
}

@(test)
test_integer_bounds :: proc(t: ^testing.T) {
	state: rand.Xoshiro256_Random_State
	gen := xoshiro(&state, 99)
	for _ in 0..<2000 {
		for n in ([]i64{1, 2, 3, 7, 1<<31 - 1}) {
			v := rand.int31_max(i32(n), gen)
			testing.expectf(t, 0 <= v && i64(v) < n, "int31_max(%v): got %v", n, v)
		}
		for n in ([]i64{1, 3, 1<<40 + 1, max(i64)}) {
			v := rand.int63_max(n, gen)
			testing.expectf(t, 0 <= v && v < n, "int63_max(%v): got %v", n, v)
		}
		for c in ([][2]i32{{-5, 5}, {min(i32), max(i32)}, {-1, 0}}) {
			v := rand.int32_range(c[0], c[1], gen)
			testing.expectf(t, c[0] <= v && v < c[1], "int32_range(%v, %v): got %v", c[0], c[1], v)
		}
		for c in ([][2]i64{{-5, 5}, {min(i64), max(i64)}, {min(i64), 0}}) {
			v := rand.int64_range(c[0], c[1], gen)
			testing.expectf(t, c[0] <= v && v < c[1], "int64_range(%v, %v): got %v", c[0], c[1], v)
		}
		for c in ([][2]u64{{0, 1}, {3, 10}, {1, max(u64)}}) {
			v := rand.uint64_range(c[0], c[1], gen)
			testing.expectf(t, c[0] <= v && v < c[1], "uint64_range(%v, %v): got %v", c[0], c[1], v)
		}
		v := rand.int128_range(-(1<<100), 1<<90, gen)
		testing.expectf(t, -(1<<100) <= v && v < 1<<90, "int128_range: got %v", v)
	}
}

@(private = "file")
perm_index :: proc(p: []int) -> int {
	return p[0] * 2 + int(p[1] > p[2])
}

@(test)
test_perm_shuffle :: proc(t: ^testing.T) {
	state: rand.Xoshiro256_Random_State
	gen := xoshiro(&state, 7)
	for n in 0..=40 {
		p := rand.perm(n, context.temp_allocator, gen)
		data := make([]int, n, context.temp_allocator)
		for &d, i in data {
			d = i
		}
		rand.shuffle(data, gen)
		seen_p := make([]bool, n, context.temp_allocator)
		seen_s := make([]bool, n, context.temp_allocator)
		ok := len(p) == n
		for i in 0..<n {
			if p[i] < 0 || p[i] >= n || seen_p[p[i]] || data[i] < 0 || data[i] >= n || seen_s[data[i]] {
				ok = false
				break
			}
			seen_p[p[i]] = true
			seen_s[data[i]] = true
		}
		testing.expectf(t, ok, "perm/shuffle(%v) is not a permutation: %v, %v", n, p, data)
	}

	N :: 60_000
	perms, shuffles: [6]int
	for _ in 0..<N {
		p := rand.perm(3, context.temp_allocator, gen)
		perms[perm_index(p)] += 1
		d := [3]int{0, 1, 2}
		rand.shuffle(d[:], gen)
		shuffles[perm_index(d[:])] += 1
	}
	chi_perm := chi_square_equal(perms[:])
	chi_shuffle := chi_square_equal(shuffles[:])
	testing.expectf(t, chi_perm < 30, "perm(3) chi-square %v: %v", chi_perm, perms)
	testing.expectf(t, chi_shuffle < 30, "shuffle of 3 chi-square %v: %v", chi_shuffle, shuffles)
}

@(test)
test_choice :: proc(t: ^testing.T) {
	state: rand.Xoshiro256_Random_State
	gen := xoshiro(&state, 11)

	data := []int{10, 20, 30}
	counts: [3]int
	for _ in 0..<3000 {
		v := rand.choice(data, gen)
		testing.expectf(t, v == 10 || v == 20 || v == 30, "choice: got %v", v)
		if v == 10 || v == 20 || v == 30 {
			counts[v / 10 - 1] += 1
		}
	}
	testing.expectf(t, counts[0] > 800 && counts[1] > 800 && counts[2] > 800, "choice counts: %v", counts)
	testing.expect_value(t, rand.choice([]int{}, gen), 0)

	Flags :: enum {A, B = 10, C}
	set_counts: [2]int
	for _ in 0..<2000 {
		f, ok := rand.choice_bit_set(bit_set[Flags]{.B, .C}, gen)
		testing.expectf(t, ok && (f == .B || f == .C), "choice_bit_set({.B, .C}): got %v, %v", f, ok)
		if f == .B {
			set_counts[0] += 1
		} else if f == .C {
			set_counts[1] += 1
		}
	}
	testing.expectf(t, set_counts[0] > 800 && set_counts[1] > 800, "choice_bit_set counts: %v", set_counts)

	only, only_ok := rand.choice_bit_set(bit_set[Flags]{.C}, gen)
	testing.expect(t, only_ok && only == .C)
	none, none_ok := rand.choice_bit_set(bit_set[Flags]{}, gen)
	testing.expect(t, !none_ok && none == .A)
}

@(test)
test_inverse_cdf_distributions :: proc(t: ^testing.T) {
	Q1 :: u64(1) << 51
	Q3 :: u64(3) << 51
	close :: proc(t: ^testing.T, name: string, got, want: f64, loc := #caller_location) {
		testing.expectf(t, abs(got - want) <= 4 * math.F64_EPSILON * abs(want), "%v: expected %v, got %v", name, want, got, loc = loc)
	}

	s := Scripted{values = {Q1}}
	close(t, "exponential(2)", rand.float64_exponential(2, scripted(&s)), 0.14384103622589045)
	s = {values = {Q1}}
	close(t, "pareto(3)", rand.float64_pareto(3, scripted(&s)), 1.100642416298209)
	s = {values = {Q1}}
	close(t, "weibull(2, 1.5)", rand.float64_weibull(2, 1.5, scripted(&s)), 0.8715758634060475)
	s = {values = {Q1}}
	close(t, "laplace(1, 2) at 0.25", rand.float64_laplace(1, 2, scripted(&s)), -0.38629436111989063)
	s = {values = {Q3}}
	close(t, "laplace(1, 2) at 0.75", rand.float64_laplace(1, 2, scripted(&s)), 2.386294361119891)
	s = {values = {Q1}}
	close(t, "gompertz(0.5, 2)", rand.float64_gompertz(0.5, 2, scripted(&s)), 0.22724322433382405)
	s = {values = {Q3}}
	close(t, "cauchy_lorentz(1, 2)", rand.float64_cauchy_lorentz(1, 2, scripted(&s)), 3)
	s = {values = {Q3}}
	close(t, "log_cauchy_lorentz(0, 1)", rand.float64_log_cauchy_lorentz(0, 1, scripted(&s)), 2.718281828459045)
	s = {values = {Q1}}
	close(t, "triangular(0, 4, 1) at 0.25", rand.float64_triangular(0, 4, 1, scripted(&s)), 1)
	s = {values = {Q3}}
	close(t, "triangular(0, 4, 1) at 0.75", rand.float64_triangular(0, 4, 1, scripted(&s)), 2.267949192431123)
	s = {values = {Q1}}
	close(t, "triangular(2, 6, nil) at 0.25", rand.float64_triangular(2, 6, nil, scripted(&s)), 2 + math.SQRT_TWO)
}

@(test)
test_distribution_moments :: proc(t: ^testing.T) {
	N :: 50_000
	Check :: struct {
		name:     string,
		draw:     proc(gen: rand.Generator) -> f64,
		mean:     f64,
		variance: f64,
	}
	checks := []Check{
		{"norm_float64",           proc(gen: rand.Generator) -> f64 { return rand.norm_float64(gen) },             0,     1},
		{"exp_float64",            proc(gen: rand.Generator) -> f64 { return rand.exp_float64(gen) },              1,     1},
		{"normal(3, 2)",           proc(gen: rand.Generator) -> f64 { return rand.float64_normal(3, 2, gen) },     3,     4},
		{"ln log_normal(0.5, 2)",  proc(gen: rand.Generator) -> f64 { return math.ln(rand.float64_log_normal(0.5, 2, gen)) }, 0.5, 4},
		{"exponential(4)",         proc(gen: rand.Generator) -> f64 { return rand.float64_exponential(4, gen) },   0.25,  0.0625},
		{"gamma(0.5, 2)",          proc(gen: rand.Generator) -> f64 { return rand.float64_gamma(0.5, 2, gen) },    1,     2},
		{"gamma(1, 3)",            proc(gen: rand.Generator) -> f64 { return rand.float64_gamma(1, 3, gen) },      3,     9},
		{"gamma(9, 0.5)",          proc(gen: rand.Generator) -> f64 { return rand.float64_gamma(9, 0.5, gen) },    4.5,   2.25},
		{"beta(2, 5)",             proc(gen: rand.Generator) -> f64 { return rand.float64_beta(2, 5, gen) },       2.0 / 7, 10.0 / 392},
		{"beta(0.5, 0.5)",         proc(gen: rand.Generator) -> f64 { return rand.float64_beta(0.5, 0.5, gen) },   0.5,   0.125},
		{"triangular(0, 4, 1)",    proc(gen: rand.Generator) -> f64 { return rand.float64_triangular(0, 4, 1, gen) }, 5.0 / 3, 13.0 / 18},
	}
	for c, i in checks {
		state: rand.Xoshiro256_Random_State
		gen := xoshiro(&state, u64(1000 + i))
		sum, sum_sq: f64
		for _ in 0..<N {
			x := c.draw(gen)
			sum += x
			sum_sq += x * x
		}
		mean := sum / N
		variance := sum_sq / N - mean * mean
		testing.expectf(t, abs(mean - c.mean) <= 6 * math.sqrt(c.variance / N), "%v: mean %v, expected %v", c.name, mean, c.mean)
		testing.expectf(t, abs(variance - c.variance) <= 0.1 * c.variance, "%v: variance %v, expected %v", c.name, variance, c.variance)
	}

	state: rand.Xoshiro256_Random_State
	gen := xoshiro(&state, 2000)
	sum_cos, sum_sin: f64
	in_range := true
	for _ in 0..<N {
		x := rand.float64_von_mises(1, 2, gen)
		in_range &&= 0 <= x && x < math.TAU
		sum_cos += math.cos(x - 1)
		sum_sin += math.sin(x - 1)
	}
	testing.expect(t, in_range, "von_mises(1, 2) left [0, 2π)")
	testing.expectf(t, abs(sum_cos / N - 0.697774657964008) <= 0.02, "von_mises(1, 2): mean cos %v, expected 0.6978", sum_cos / N)
	testing.expectf(t, abs(sum_sin / N) <= 0.02, "von_mises(1, 2): mean sin %v, expected 0", sum_sin / N)
}
