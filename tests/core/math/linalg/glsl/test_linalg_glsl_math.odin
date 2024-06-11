// Tests "linalg_glsl_math.odin" in "core:math/linalg/glsl".
package test_core_math_linalg_glsl_math

import glsl "core:math/linalg/glsl"

import "core:math"
import "core:testing"

@test
test_fract_f32 :: proc(t: ^testing.T) {
	r: f32

	Datum :: struct {
		i: int,
		v: f32,
		e: f32,
	}
	@static data := []Datum{
		{ 0, 10.5, 0.5 }, // Issue #1574 fract in linalg/glm is broken
		{ 1, -10.5, -0.5 },
		{ 2, math.F32_MIN, math.F32_MIN }, // 0x1p-126
		{ 3, -math.F32_MIN, -math.F32_MIN },
		{ 4, 0.0, 0.0 },
		{ 5, -0.0, -0.0 },
		{ 6, 1, 0.0 },
		{ 7, -1, -0.0 },
		{ 8, 0h3F80_0001, 0h3400_0000 }, // 0x1.000002p+0, 0x1p-23
		{ 9, -0h3F80_0001, -0h3400_0000 },
	}

	for d, i in data {
		assert(i == d.i)
		r = glsl.fract(d.v)
		testing.expectf(t, r == d.e, "%v (%h) -> %v (%h) != %v", d.v, d.v, r, r, d.e)
	}
}

@test
test_fract_f64 :: proc(t: ^testing.T) {
	r: f64

	Datum :: struct {
		i: int,
		v: f64,
		e: f64,
	}
	@static data := []Datum{
		{ 0, 10.5, 0.5 }, // Issue #1574 fract in linalg/glm is broken
		{ 1, -10.5, -0.5 },
		{ 2, math.F64_MIN, math.F64_MIN }, // 0x1p-1022
		{ 3, -math.F64_MIN, -math.F64_MIN },
		{ 4, 0.0, 0.0 },
		{ 5, -0.0, -0.0 },
		{ 6, 1, 0.0 },
		{ 7, -1, -0.0 },
		{ 8, 0h3FF0_0000_0000_0001, 0h3CB0_0000_0000_0000 }, // 0x1.0000000000001p+0, 0x1p-52
		{ 9, -0h3FF0_0000_0000_0001, -0h3CB0_0000_0000_0000 },
	}

	for d, i in data {
		assert(i == d.i)
		r = glsl.fract(d.v)
		testing.expectf(t, r == d.e, "%v (%h) -> %v (%h) != %v", d.v, d.v, r, r, d.e)
	}
}