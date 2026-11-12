package test_core_math_ease

import "core:math/ease"
import "core:testing"
import "core:time"

@(private="file")
NON_INVERTIBLE :: bit_set[ease.Ease]{
	.Elastic_In, .Elastic_Out, .Elastic_In_Out,
	.Back_In, .Back_Out, .Back_In_Out,
	.Bounce_In, .Bounce_Out, .Bounce_In_Out,
}

@(private="file")
Case :: struct {
	type:    ease.Ease,
	inverse: bool,
	p:       f64,
	want:    f64,
}

@(private="file")
endpoints :: proc(t: ^testing.T, $T: typeid) {
	for e in ease.Ease {
		for p in ([]T{0, 1}) {
			got := ease.ease(e, p)
			testing.expectf(t, got == p, "%v %v(%v) = %v, want %v", typeid_of(T), e, p, got, p)
			if e not_in NON_INVERTIBLE {
				got = ease.ease_inverse(e, p)
				testing.expectf(t, got == p, "%v %v_inverse(%v) = %v, want %v", typeid_of(T), e, p, got, p)
			}
		}
	}
}

@(test)
test_endpoints :: proc(t: ^testing.T) {
	endpoints(t, f16)
	endpoints(t, f32)
	endpoints(t, f64)
}

@(private="file")
check :: proc(t: ^testing.T, $T: typeid, cases: []Case, tolerance: f64) {
	for c in cases {
		p := T(c.p)
		got := f64(ease.ease_inverse(c.type, p) if c.inverse else ease.ease(c.type, p))
		testing.expectf(t, abs(got - c.want) <= tolerance, "%v %v%s(%v) = %v, want %v", typeid_of(T), c.type, "_inverse" if c.inverse else "", p, got, c.want)
	}
}

@(test)
test_accuracy :: proc(t: ^testing.T) {
	f64_cases := [?]Case{
		{.Bounce_Out,      false, 0.9486783622955235,     0.9730188646431964},
		{.Bounce_In,       false, 0.031,                  0.0231012},
		{.Bounce_In_Out,   false, 0.9999999999990004,     0.9999999999989204},
		{.Circular_In,     false, 0.9999999899999996,     0.9998585786414058},
		{.Circular_Out,    true,  0.9999999899999996,     0.9998585786414058},
		{.Sine_In,         true,  1.0000000000000006e-12, 9.003163161571813e-07},
		{.Sine_In_Out,     true,  1.0000000000000006e-12, 6.366197723676876e-07},
		{.Circular_In_Out, true,  1.0000000000000006e-12, 9.999999999995002e-07},
	}
	check(t, f64, f64_cases[:], 2.0 / (1 << 52))

	f32_cases := [?]Case{
		{.Bounce_Out,      false, 0.834,         0.9150036966130062},
		{.Bounce_In,       false, 0.166,         0.08499629606404349},
		{.Elastic_Out,     false, 0.077754684,   1.0099059356525761},
		{.Elastic_In,      false, 0.933,         0.12648664914202226},
		{.Sine_In,         true,  1.0000003e-08, 9.003164341177676e-05},
		{.Sine_In_Out,     true,  1.0000003e-08, 6.366198563088817e-05},
		{.Circular_In_Out, true,  1.0000003e-08, 0.0001000000125188017},
	}
	check(t, f32, f32_cases[:], 1.0 / (1 << 23))

	f16_cases := [?]Case{
		{.Bounce_In,       false, 0.122, 0.04002686361691958},
		{.Bounce_Out,      false, 0.878, 0.9598783899872587},
		{.Elastic_Out,     false, 0.065, 0.8464010432810187},
		{.Cubic_In_Out,    true,  1e-07, 0.00310039267962539},
		{.Quartic_In_Out,  true,  2e-07, 0.012227223281822557},
		{.Quintic_In_Out,  true,  2e-07, 0.025683622336206652},
	}
	check(t, f16, f16_cases[:], 1.0 / (1 << 10))
}

@(test)
test_flux_delay :: proc(t: ^testing.T) {
	m := ease.flux_init(f64)
	defer ease.flux_destroy(m)

	a, b: f64
	_ = ease.flux_to(&m, &a, 1, .Linear, time.Second, 0.25)
	_ = ease.flux_to(&m, &b, 1, .Linear, time.Second, 1)

	ease.flux_update(&m, 1)
	testing.expect_value(t, a, 0.75)
	testing.expect_value(t, b, 0)

	ease.flux_update(&m, 0.25)
	testing.expect_value(t, a, 1)
	testing.expect_value(t, b, 0.25)
	testing.expect_value(t, len(m.values), 1)
}

@(test)
test_flux_time_left :: proc(t: ^testing.T) {
	m := ease.flux_init(f64)
	defer ease.flux_destroy(m)

	v: f64
	_ = ease.flux_to(&m, &v, 1, .Linear, 2 * time.Second, 0.5)
	testing.expect_value(t, ease.flux_tween_time_left(m, &v), 2.5)

	ease.flux_update(&m, 1)
	testing.expect_value(t, ease.flux_tween_time_left(m, &v), 1.5)

	ease.flux_update(&m, 1.5)
	testing.expect_value(t, ease.flux_tween_time_left(m, &v), 0)
}

@(test)
test_flux_goal :: proc(t: ^testing.T) {
	m := ease.flux_init(f32)
	defer ease.flux_destroy(m)

	vs := [?]f32{1000, 1, -3.7}
	goals := [?]f32{0.001, 1e-8, 12.9}
	for &v, i in vs {
		_ = ease.flux_to(&m, &v, goals[i], .Linear)
	}
	ease.flux_update(&m, 1)
	for v, i in vs {
		testing.expect_value(t, v, goals[i])
	}
}

@(private="file")
Restart_State :: struct {
	value:    f64,
	restarts: int,
}

@(test)
test_flux_restart_from_on_complete :: proc(t: ^testing.T) {
	m := ease.flux_init(f64)
	defer ease.flux_destroy(m)

	s: Restart_State
	tween := ease.flux_to(&m, &s.value, 1, .Linear)
	tween.data = &s
	tween.on_complete = proc(flux: ^ease.Flux_Map(f64), data: rawptr) {
		s := (^Restart_State)(data)
		s.restarts += 1
		_ = ease.flux_to(flux, &s.value, 0, .Linear)
	}

	ease.flux_update(&m, 1)
	testing.expect_value(t, s.value, 1)
	testing.expect_value(t, s.restarts, 1)
	testing.expect_value(t, len(m.values), 1)

	ease.flux_update(&m, 0.5)
	testing.expect_value(t, s.value, 0.5)

	ease.flux_update(&m, 0.5)
	testing.expect_value(t, s.value, 0)
	testing.expect_value(t, s.restarts, 1)
	testing.expect_value(t, len(m.values), 0)
}

@(test)
test_flux_callback_adds_tweens :: proc(t: ^testing.T) {
	m := ease.flux_init(f64, 1)
	defer ease.flux_destroy(m)

	vs: [64]f64
	tween := ease.flux_to(&m, &vs[0], 1, .Linear)
	tween.data = &vs
	tween.on_start = proc(flux: ^ease.Flux_Map(f64), data: rawptr) {
		vs := (^[64]f64)(data)
		for i in 1..<len(vs) {
			_ = ease.flux_to(flux, &vs[i], 1, .Linear)
		}
	}

	ease.flux_update(&m, 0.5)
	testing.expect_value(t, len(m.values), 64)
	testing.expect_value(t, vs[0], 0.5)
	testing.expect_value(t, m.values[&vs[0]].progress, 0.5)
	started := 0
	for i in 1..<len(vs) {
		if m.values[&vs[i]].inited {
			started += 1
		}
	}
	testing.expect_value(t, started, 0)

	ease.flux_update(&m, 0.5)
	testing.expect_value(t, len(m.values), 63)
	testing.expect_value(t, vs[0], 1)
	halfway := 0
	for i in 1..<len(vs) {
		if vs[i] == 0.5 {
			halfway += 1
		}
	}
	testing.expect_value(t, halfway, 63)
}

@(private="file")
Change_State :: struct {
	value:     f64,
	other:     f64,
	completes: int,
}

@(test)
test_flux_callback_changes :: proc(t: ^testing.T) {
	{
		m := ease.flux_init(f64)
		defer ease.flux_destroy(m)

		s: Change_State
		tween := ease.flux_to(&m, &s.value, 1, .Linear)
		tween.data = &s
		tween.on_update = proc(flux: ^ease.Flux_Map(f64), data: rawptr) {
			s := (^Change_State)(data)
			_ = ease.flux_to(flux, &s.value, 0, .Linear)
		}

		ease.flux_update(&m, 1)
		testing.expect_value(t, s.value, 1)
		testing.expect_value(t, len(m.values), 1)

		ease.flux_update(&m, 0.5)
		testing.expect_value(t, s.value, 0.5)
	}
	{
		m := ease.flux_init(f64)
		defer ease.flux_destroy(m)

		s: Change_State
		tween := ease.flux_to(&m, &s.value, 1, .Linear)
		tween.data = &s
		tween.on_update = proc(flux: ^ease.Flux_Map(f64), data: rawptr) {
			s := (^Change_State)(data)
			_ = ease.flux_stop(flux, &s.value)
		}
		tween.on_complete = proc(flux: ^ease.Flux_Map(f64), data: rawptr) {
			s := (^Change_State)(data)
			s.completes += 1
		}

		ease.flux_update(&m, 1)
		testing.expect_value(t, s.value, 1)
		testing.expect_value(t, s.completes, 0)
		testing.expect_value(t, len(m.values), 0)
	}
	{
		m := ease.flux_init(f64)
		defer ease.flux_destroy(m)

		s: Change_State
		tween := ease.flux_to(&m, &s.value, 1, .Linear)
		tween.data = &s
		tween.on_start = proc(flux: ^ease.Flux_Map(f64), data: rawptr) {
			ease.flux_clear(flux)
		}
		_ = ease.flux_to(&m, &s.other, 1, .Linear)

		ease.flux_update(&m, 0.5)
		testing.expect_value(t, s.value, 0)
		testing.expect_value(t, len(m.values), 0)
	}
}
