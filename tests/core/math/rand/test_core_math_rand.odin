package test_core_math_rand

import "core:math"
import "core:math/rand"
import "core:testing"

Generator :: struct {
	name:   string,
	gen:    rand.Generator,
	biased: bool,
}

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
