package test_core_math_linalg_glsl_math

import glsl "core:math/linalg/glsl"

import "core:math"
import "core:testing"

@test
test_fract_vector :: proc(t: ^testing.T) {
	x := glsl.dvec4{-0.25, 1.75, -2.5, 3}
	e := glsl.dvec4{0.75, 0.75, 0.5, 0}
	testing.expect_value(t, glsl.fract(x), e)
	testing.expect_value(t, glsl.fract(x.xyz), e.xyz)
	testing.expect_value(t, glsl.fract(x.xy), e.xy)
	testing.expect_value(t, glsl.fract(glsl.vec4(x)), glsl.vec4(e))
	testing.expect_value(t, glsl.fract(glsl.vec3(x.xyz)), glsl.vec3(e.xyz))
	testing.expect_value(t, glsl.fract(glsl.vec2(x.xy)), glsl.vec2(e.xy))
}

@test
test_mod :: proc(t: ^testing.T) {
	Datum :: struct {
		x, y, e: f64,
	}
	@static data := []Datum{
		{ -1, 3, 2 },
		{ 1, -3, -2 },
		{ -1, -3, -1 },
		{ 5.5, 2, 1.5 },
		{ -7.5, 2, 0.5 },
		{ 7.5, -2, -0.5 },
		{ 6, 3, 0 },
		{ -6, 3, 0 },
		{ 0.75, 0.25, 0 },
	}
	for d in data {
		r := glsl.mod(d.x, d.y)
		testing.expectf(t, r == d.e, "mod(%v, %v) = %v, want %v", d.x, d.y, r, d.e)
		f := glsl.mod(f32(d.x), f32(d.y))
		testing.expectf(t, f == f32(d.e), "mod(f32(%v), f32(%v)) = %v, want %v", d.x, d.y, f, d.e)
	}

	x := glsl.dvec4{-1, -7.5, 7.5, 5.5}
	y := glsl.dvec4{3, 2, -2, 2}
	e := glsl.dvec4{2, 0.5, -0.5, 1.5}
	testing.expect_value(t, glsl.mod(x, y), e)
	testing.expect_value(t, glsl.mod(x.xyz, y.xyz), e.xyz)
	testing.expect_value(t, glsl.mod(x.xy, y.xy), e.xy)
	testing.expect_value(t, glsl.mod(glsl.vec4(x), glsl.vec4(y)), glsl.vec4(e))
	testing.expect_value(t, glsl.mod(glsl.vec3(x.xyz), glsl.vec3(y.xyz)), glsl.vec3(e.xyz))
	testing.expect_value(t, glsl.mod(glsl.vec2(x.xy), glsl.vec2(y.xy)), glsl.vec2(e.xy))

	es := glsl.dvec4{2, 1.5, 1.5, 2.5}
	testing.expect_value(t, glsl.mod(x, f64(3)), es)
	testing.expect_value(t, glsl.mod(x.xyz, f64(3)), es.xyz)
	testing.expect_value(t, glsl.mod(x.xy, f64(3)), es.xy)
	testing.expect_value(t, glsl.mod(glsl.vec4(x), f32(3)), glsl.vec4(es))
	testing.expect_value(t, glsl.mod(glsl.vec3(x.xyz), f32(3)), glsl.vec3(es.xyz))
	testing.expect_value(t, glsl.mod(glsl.vec2(x.xy), f32(3)), glsl.vec2(es.xy))
}

@test
test_refract_grazing :: proc(t: ^testing.T) {
	i := glsl.dvec4{1, 0, 0, 0}
	n := glsl.dvec4{0, 1, 0, 0}
	testing.expect_value(t, glsl.refract(i, n, 1), i)
	testing.expect_value(t, glsl.refract(i.xyz, n.xyz, 1), i.xyz)
	testing.expect_value(t, glsl.refract(i.xy, n.xy, 1), i.xy)
	testing.expect_value(t, glsl.refract(glsl.vec4(i), glsl.vec4(n), 1), glsl.vec4(i))
	testing.expect_value(t, glsl.refract(glsl.vec3(i.xyz), glsl.vec3(n.xyz), 1), glsl.vec3(i.xyz))
	testing.expect_value(t, glsl.refract(glsl.vec2(i.xy), glsl.vec2(n.xy), 1), glsl.vec2(i.xy))
}

@test
test_radians_degrees_range :: proc(t: ^testing.T) {
	within_1ulp_f32 :: proc(got, want: f32) -> bool {
		return got == want || got == math.nextafter(want, math.inf_f32(1)) || got == math.nextafter(want, math.inf_f32(-1))
	}
	within_1ulp_f64 :: proc(got, want: f64) -> bool {
		return got == want || got == math.nextafter(want, math.inf_f64(1)) || got == math.nextafter(want, math.inf_f64(-1))
	}

	dg := glsl.degrees(f32(1e36))
	testing.expectf(t, within_1ulp_f32(dg, 5.7295778889355604e+37), "degrees(f32(1e36)) = %v, want %v", dg, f32(5.7295778889355604e+37))
	rd := glsl.radians(f32(3e38))
	testing.expectf(t, within_1ulp_f32(rd, 5.2359877041222938e+36), "radians(f32(3e38)) = %v, want %v", rd, f32(5.2359877041222938e+36))
	ddg := glsl.degrees(f64(1e306))
	testing.expectf(t, within_1ulp_f64(ddg, 5.7295779513082323e+307), "degrees(1e306) = %v, want %v", ddg, 5.7295779513082323e+307)
	drd := glsl.radians(f64(1.7e308))
	testing.expectf(t, within_1ulp_f64(drd, 2.9670597283903601e+306), "radians(1.7e308) = %v, want %v", drd, 2.9670597283903601e+306)

	testing.expect_value(t, glsl.degrees(f32(1)), f32(360.0 / glsl.TAU))
	testing.expect_value(t, glsl.radians(f32(1)), f32(glsl.TAU / 360.0))
	testing.expect_value(t, glsl.degrees(glsl.vec4{1e36, 1, -1e36, 0}), glsl.vec4{glsl.degrees(f32(1e36)), glsl.degrees(f32(1)), glsl.degrees(f32(-1e36)), 0})
}
