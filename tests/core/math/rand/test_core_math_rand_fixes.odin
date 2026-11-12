package test_core_math_rand

import "base:runtime"
import "core:math"
import "core:math/rand"
import "core:testing"

@(private = "file")
Mock_State :: struct {
	value: u64,
	step:  u64,
}

@(private = "file")
mock_generator_proc :: proc(data: rawptr, mode: runtime.Random_Generator_Mode, p: []byte) {
	state := (^Mock_State)(data)
	if mode != .Read {
		return
	}
	for i := 0; i < len(p); i += 8 {
		runtime.mem_copy_non_overlapping(&p[i], &state.value, min(len(p) - i, 8))
	}
	state.value += state.step
}

@(private = "file")
mock_generator :: proc(state: ^Mock_State) -> rand.Generator {
	return {mock_generator_proc, state}
}

@(test)
test_float_range_bounds :: proc(t: ^testing.T) {
	c64 := [][2]f64{
		{-1, -1}, {0, 0}, {5, 5}, {-2, -1}, {1, 2}, {0, 1}, {-1, 0},
		{0, 5e-324}, {-5e-324, 0}, {-5e-324, 5e-324},
		{1, math.nextafter(f64(1), 2)}, {-3, math.nextafter(f64(-3), 0)},
		{-math.F64_MAX, math.F64_MAX}, {-1e308, 1e308}, {-math.F64_MAX, -1e300}, {1e300, math.F64_MAX},
	}
	c32 := [][2]f32{
		{-1, -1}, {0, 0}, {5, 5}, {-2, -1}, {1, 2}, {0, 1}, {-1, 0},
		{0, 1e-45}, {-1e-45, 0}, {-1e-45, 1e-45},
		{1, math.nextafter(f32(1), 2)}, {-3, math.nextafter(f32(-3), 0)},
		{-math.F32_MAX, math.F32_MAX}, {-3e38, 3e38}, {-math.F32_MAX, -1e36}, {1e36, math.F32_MAX},
	}
	values := []u64{0, max(u64), 1<<52, 1<<23}
	for value in values {
		state := Mock_State{value = value}
		gen := mock_generator(&state)
		for c in c64 {
			v := rand.float64_range(c[0], c[1], gen)
			ok := v == c[0] if c[0] == c[1] else c[0] <= v && v < c[1]
			testing.expectf(t, ok, "float64_range(%v, %v) with generator %x: got %v", c[0], c[1], value, v)
		}
		for c in c32 {
			v := rand.float32_range(c[0], c[1], gen)
			ok := v == c[0] if c[0] == c[1] else c[0] <= v && v < c[1]
			testing.expectf(t, ok, "float32_range(%v, %v) with generator %x: got %v", c[0], c[1], value, v)
		}
	}

	half64 := Mock_State{value = 1<<52}
	testing.expect_value(t, rand.float64_range(-math.F64_MAX, math.F64_MAX, mock_generator(&half64)), 0)
	half32 := Mock_State{value = 1<<23}
	testing.expect_value(t, rand.float32_range(-math.F32_MAX, math.F32_MAX, mock_generator(&half32)), 0)
}

@(test)
test_choice_enum_aliases :: proc(t: ^testing.T) {
	Aliased :: enum {A = 0, B = 0, C = 2}
	Wide :: enum u64 {X = 1<<63 + 5, Y, Z}

	state := Mock_State{step = 1}
	gen := mock_generator(&state)
	seen_aliased: [3]int
	seen_wide: [3]int
	for _ in 0..<30 {
		a := rand.choice_enum(Aliased, gen)
		testing.expectf(t, a == .A || a == .C, "choice_enum(Aliased): got %v", int(a))
		if int(a) >= 0 && int(a) < 3 {
			seen_aliased[int(a)] += 1
		}
		w := rand.choice_enum(Wide, gen)
		testing.expectf(t, w >= .X && w <= .Z, "choice_enum(Wide): got %v", u64(w))
		if w >= .X && w <= .Z {
			seen_wide[u64(w) - u64(Wide.X)] += 1
		}
	}
	testing.expectf(t, seen_aliased[0] > 0 && seen_aliased[2] > 0, "choice_enum(Aliased): values seen %v", seen_aliased)
	testing.expectf(t, seen_wide[0] > 0 && seen_wide[1] > 0 && seen_wide[2] > 0, "choice_enum(Wide): values seen %v", seen_wide)
}

@(private = "file")
Script_State :: struct {
	values: []u64,
	used:   int,
	sm:     u64,
}

@(private = "file")
script_generator_proc :: proc(data: rawptr, mode: runtime.Random_Generator_Mode, p: []byte) {
	state := (^Script_State)(data)
	if mode != .Read {
		return
	}
	v: u64
	if state.used < len(state.values) {
		v = state.values[state.used]
	} else {
		state.sm += 0x9E3779B97F4A7C15
		z := state.sm
		z = (z ~ (z >> 30)) * 0xBF58476D1CE4E5B9
		z = (z ~ (z >> 27)) * 0x94D049BB133111EB
		v = z ~ (z >> 31)
	}
	state.used += 1
	for i := 0; i < len(p); i += 8 {
		runtime.mem_copy_non_overlapping(&p[i], &v, min(len(p) - i, 8))
	}
}

@(private = "file")
script_generator :: proc(state: ^Script_State) -> rand.Generator {
	return {script_generator_proc, state}
}

@(test)
test_zipf :: proc(t: ^testing.T) {
	state := Script_State{sm = 1}
	z, ok := rand.zipf_create(2, 1, 100, script_generator(&state))
	testing.expect(t, ok)
	N :: 20_000
	zeros, above := 0, 0
	for _ in 0..<N {
		k := rand.zipf_uint64(z)
		if k == 0 {
			zeros += 1
		}
		if k > 100 {
			above += 1
		}
	}
	total: f64
	for k in 1..=101 {
		total += 1 / f64(k*k)
	}
	p0 := 1 / total
	testing.expect_value(t, above, 0)
	testing.expectf(t, abs(f64(zeros) - N*p0) < 6*math.sqrt(N*p0*(1 - p0)), "zipf_uint64(s=2, v=1, imax=100): %v zeros in %v draws, expected about %.0f", zeros, N, N*p0)

	edges := [][3]f64{{5, 1e6, 10}, {10, 1e6, 0}, {1.001, 1e6, 3}, {2, 1, 0}, {50, 1, 3}}
	for e in edges {
		for first in ([]u64{0, max(u64)}) {
			values := []u64{first}
			edge_state := Script_State{values = values, sm = 2}
			ze, eok := rand.zipf_create(e[0], e[1], u64(e[2]), script_generator(&edge_state))
			testing.expectf(t, eok, "zipf_create(%v, %v, %v) failed", e[0], e[1], e[2])
			k := rand.zipf_uint64(ze)
			testing.expectf(t, k <= u64(e[2]), "zipf_uint64(s=%v, v=%v, imax=%v) with first draw %x: got %v", e[0], e[1], e[2], first, k)
		}
	}

	_, underflow_ok := rand.zipf_create(300, 1e6, 10, script_generator(&state))
	testing.expect(t, !underflow_ok)
}

@(test)
test_gamma_nan_alpha :: proc(t: ^testing.T) {
	testing.expect_assert(t, "float64_gamma: alpha must be finite, and alpha and beta must be > 0.0")
	state := Script_State{sm = 3}
	_ = rand.float64_gamma(math.nan_f64(), 1, script_generator(&state))
}

@(test)
test_gamma_inf_alpha :: proc(t: ^testing.T) {
	testing.expect_assert(t, "float64_gamma: alpha must be finite, and alpha and beta must be > 0.0")
	state := Script_State{sm = 3}
	_ = rand.float64_gamma(math.inf_f64(1), 1, script_generator(&state))
}

@(test)
test_beta_nan_alpha :: proc(t: ^testing.T) {
	testing.expect_assert(t, "float64_beta: alpha and beta must be finite and > 0.0")
	state := Script_State{sm = 3}
	_ = rand.float64_beta(math.nan_f64(), 1, script_generator(&state))
}

@(test)
test_von_mises_nan_kappa :: proc(t: ^testing.T) {
	testing.expect_assert(t, "float64_von_mises: kappa must be >= 0.0")
	state := Script_State{sm = 3}
	_ = rand.float64_von_mises(0, math.nan_f64(), script_generator(&state))
}

@(test)
test_von_mises_range :: proc(t: ^testing.T) {
	state := Script_State{sm = 4}
	gen := script_generator(&state)
	params := [][2]f64{{0, 1}, {1, 4}, {0, 100}, {math.TAU - 0.01, 50}, {-3, 2}}
	for p in params {
		outside := 0
		for _ in 0..<10_000 {
			r := rand.float64_von_mises(p[0], p[1], gen)
			if !(r >= 0 && r < math.TAU) {
				outside += 1
			}
		}
		testing.expectf(t, outside == 0, "float64_von_mises(%v, %v): %v of 10000 draws outside [0, TAU)", p[0], p[1], outside)
	}
}

@(test)
test_beta_tiny_shapes :: proc(t: ^testing.T) {
	state := Script_State{sm = 5}
	gen := script_generator(&state)
	N :: 20_000
	sum: f64
	below := 0
	for _ in 0..<N {
		x := rand.float64_beta(0.001, 0.001, gen)
		sum += x
		if x < 0.5 {
			below += 1
		}
	}
	testing.expectf(t, abs(sum/N - 0.5) < 0.02, "float64_beta(0.001, 0.001): mean %v, expected 0.5", sum/N)
	testing.expectf(t, abs(f64(below)/N - 0.5) < 0.02, "float64_beta(0.001, 0.001): P(X < 0.5) = %v, expected 0.5", f64(below)/N)
}

@(test)
test_gamma_huge_alpha :: proc(t: ^testing.T) {
	state := Script_State{sm = 6}
	gen := script_generator(&state)
	N :: 20_000
	ALPHA :: 1e18
	sum, sum2: f64
	for _ in 0..<N {
		z := (rand.float64_gamma(ALPHA, 1, gen) - ALPHA) / math.sqrt(f64(ALPHA))
		sum += z
		sum2 += z*z
	}
	mean := sum/N
	variance := sum2/N - mean*mean
	testing.expectf(t, abs(mean) < 0.05, "float64_gamma(1e18, 1): standardized mean %v, expected 0", mean)
	testing.expectf(t, abs(variance - 1) < 0.06, "float64_gamma(1e18, 1): standardized variance %v, expected 1", variance)
}

@(test)
test_distribution_edge_draws :: proc(t: ^testing.T) {
	zero := Script_State{values = []u64{0}, sm = 7}
	testing.expect(t, !math.is_inf(rand.float64_laplace(0, 1, script_generator(&zero))))

	exp_tail := Script_State{values = []u64{0xFFFFFF00, 0}, sm = 8}
	testing.expect(t, !math.is_inf(rand.exp_float64(script_generator(&exp_tail))))
	norm_tail_up := Script_State{values = []u64{0x7FFFFF80, 0, 0}, sm = 9}
	testing.expect(t, !math.is_inf(rand.norm_float64(script_generator(&norm_tail_up))))
	norm_tail_down := Script_State{values = []u64{0x80000000, 0, 0}, sm = 10}
	testing.expect(t, !math.is_inf(rand.norm_float64(script_generator(&norm_tail_down))))

	half := Script_State{values = []u64{1<<52}, sm = 11}
	testing.expect_value(t, rand.float32_pareto(2, script_generator(&half)), f32(math.SQRT_TWO))

	tiny := Script_State{values = []u64{1}, sm = 12}
	testing.expect_value(t, rand.float32_triangular(0, 1, nil, script_generator(&tiny)), f32(1.0 / (1 << 27)))
	wide := Script_State{values = []u64{1<<52, 1<<52}, sm = 13}
	testing.expect_value(t, rand.float64_triangular(-math.F64_MAX, math.F64_MAX, nil, script_generator(&wide)), 0)
	testing.expect_value(t, rand.float64_triangular(-math.F64_MAX, math.F64_MAX, 0, script_generator(&wide)), 0)

	gompertz := Script_State{values = []u64{1}, sm = 14}
	testing.expect_value(t, rand.float64_gompertz(1, 1, script_generator(&gompertz)), 1.0 / (1 << 53))
}
