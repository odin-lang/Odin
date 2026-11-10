package test_core_math_linalg_glsl_math

import glsl "core:math/linalg/glsl"

import "core:testing"

@test
test_normalize_scalar :: proc(t: ^testing.T) {
	for v in ([]f64{-1000, -10, -0.5, 0.5, 3, 1000}) {
		e := f64(1) if v > 0 else -1
		d := glsl.normalize(v)
		testing.expectf(t, d == e, "normalize(%v) = %v, want %v", v, d, e)
		f := glsl.normalize(f32(v))
		testing.expectf(t, f == f32(e), "normalize(f32(%v)) = %v, want %v", v, f, e)
	}
}
