// Tests issue #5881 https://github.com/odin-lang/Odin/issues/5881
package test_issues

import "core:math"
import "core:math/rand"
import "core:testing"
import "base:runtime"

// Helper: compute chi-square statistic for counts vs equal-expected across k bins
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
expect_u64_bit_balance :: proc(t: ^testing.T, gen: rand.Generator, samples: int, sigma_k: f64 = 6) {
	ones: [64]int
	for i := 0; i < samples; i += 1 {
		v := rand.uint64(gen)
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
			testing.expectf(t, false, "u64 bit %d imbalance: ones=%d samples=%d diff=%.1f limit=%.1f", b, ones[b], samples, diff, limit)
			return
		}
	}
}

// Uniformity sanity via 4D sign orthant chi-square with modest sample size.
expect_quaternion_sign_uniformity :: proc(t: ^testing.T, gen: rand.Generator, iterations: int) {
	counts: [16]int
	for _ in 0..<iterations {
		// Map 4D signs to 0..15 index
		x := rand.float64_range(-10, 10, gen)
		y := rand.float64_range(-10, 10, gen)
		z := rand.float64_range(-10, 10, gen)
		w := rand.float64_range(-10, 10, gen)
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
	testing.expectf(t, chi < 55.0, "4D sign chi-square too high: %.3f (counts=%v)", chi, counts)
}

@test
test_runtime_default_rng_properties :: proc(t: ^testing.T) {
	// Determinism with same seed
	state1 := rand.create(123456789)
	state2 := rand.create(123456789)
	gen1 := rand.default_random_generator(&state1)
	gen2 := rand.default_random_generator(&state2)
	a1 := rand.uint64(gen1)
	a2 := rand.uint64(gen2)
	testing.expect(t, a1 == a2, "default RNG not deterministic with same seed")

	// Info flags
	info := rand.query_info(gen1)
	testing.expect(t, runtime.Random_Generator_Query_Info_Flag.Uniform in info, "default RNG must be Uniform")
	testing.expect(t, runtime.Random_Generator_Query_Info_Flag.Resettable in info, "default RNG must be Resettable")

	// Bit balance and sign uniformity (modest samples to keep CI fast)
	expect_u64_bit_balance(t, gen1, 200_000)
	expect_quaternion_sign_uniformity(t, gen1, 200_000)
}


