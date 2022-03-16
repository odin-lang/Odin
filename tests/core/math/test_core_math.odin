// Tests "math.odin" in "core:math".
// Must be run with `-collection:tests=` flag, e.g.
// ./odin run tests/core/math/test_core_math.odin -collection:tests=./tests
package test_core_math

import "core:fmt"
import "core:math"
import "core:testing"
import tc "tests:common"

main :: proc() {
    t := testing.T{}

	test_classify_f16(&t)
	test_classify_f32(&t)
	test_classify_f64(&t)

	test_trunc_f16(&t)
	test_trunc_f32(&t)
	test_trunc_f64(&t)

	tc.report(&t)
}

@test
test_classify_f16 :: proc(t: ^testing.T) {

	using math
	using Float_Class

	r: Float_Class

	Datum :: struct {
		i: int,
		v: f16,
		e: math.Float_Class,
	}
	@static data := []Datum{
		{ 0, 1.2, Normal },
		{ 1, 0h0001, Subnormal },
		{ 2, 0.0, Zero },
		{ 3, -0.0, Neg_Zero },
		{ 4, SNAN_F16, NaN },
		{ 5, QNAN_F16, NaN },
		{ 6, INF_F16, Inf },
		{ 7, NEG_INF_F16, Neg_Inf },
	}

	for d, i in data {
		assert(i == d.i)
		r = classify_f16(d.v)
		tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(%h) -> %v != %v", i, #procedure, d.v, r, d.e))
	}

	/* Check all subnormals (exponent 0, 10-bit significand non-zero) */
	for i :u16 = 1; i < 0x400; i += 1 {
		v :f16 = transmute(f16)i
		r = classify_f16(v)
		e :Float_Class: Subnormal
		tc.expect(t, r == e, fmt.tprintf("i:%d %s(%h) -> %v != %v", i, #procedure, v, r, e))
	}
}

@test
test_classify_f32 :: proc(t: ^testing.T) {

	using math
	using Float_Class

	r: Float_Class

	Datum :: struct {
		i: int,
		v: f32,
		e: math.Float_Class,
	}
	@static data := []Datum{
		{ 0, 1.2, Normal },
		{ 1, 0h0000_0001, Subnormal },
		{ 2, 0.0, Zero },
		{ 3, -0.0, Neg_Zero },
		{ 4, SNAN_F32, NaN },
		{ 5, QNAN_F32, NaN },
		{ 6, INF_F32, Inf },
		{ 7, NEG_INF_F32, Neg_Inf },
	}

	for d, i in data {
		assert(i == d.i)
		r = classify_f32(d.v)
		tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(%h) -> %v != %v", i, #procedure, d.v, r, d.e))
	}
}

@test
test_classify_f64 :: proc(t: ^testing.T) {

	using math
	using Float_Class

	r: Float_Class

	Datum :: struct {
		i: int,
		v: f64,
		e: math.Float_Class,
	}
	@static data := []Datum{
		{ 0, 1.2, Normal },
		{ 1, 0h0000_0000_0000_0001, Subnormal },
		{ 2, 0.0, Zero },
		{ 3, -0.0, Neg_Zero },
		{ 4, SNAN_F64, NaN },
		{ 5, QNAN_F64, NaN },
		{ 6, INF_F64, Inf },
		{ 7, NEG_INF_F64, Neg_Inf },
	}

	for d, i in data {
		assert(i == d.i)
		r = classify_f64(d.v)
		tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(%h) -> %v != %v", i, #procedure, d.v, r, d.e))
	}
}

@test
test_trunc_f16 :: proc(t: ^testing.T) {

	using math

	r, v: f16

	Datum :: struct {
		i: int,
		v: f16,
		e: f16,
	}
	@static data := []Datum{
		{ 0, 10.5, 10 }, // Issue #1574 fract in linalg/glm is broken
		{ 1, -10.5, -10 },

		{ 2, F16_MAX, F16_MAX },
		{ 3, -F16_MAX, -F16_MAX },
		{ 4, F16_MIN, 0.0 },
		{ 5, -F16_MIN, -0.0 },
		{ 6, 0.0, 0.0 },
		{ 7, -0.0, -0.0 },
		{ 8, 1, 1 },
		{ 9, -1, -1 },
		{ 10, INF_F16, INF_F16 },
		{ 11, NEG_INF_F16, NEG_INF_F16 },

		/* From https://en.wikipedia.org/wiki/Half-precision_floating-point_format */
		{ 12, 0h3C01, 1 }, // 0x1.004p+0 (smallest > 1)
		{ 13, -0h3C01, -1 },
		{ 14, 0h3BFF, 0.0 }, // 0x1.ffcp-1 (largest < 1)
		{ 15, -0h3BFF, -0.0 },
		{ 16, 0h0001, 0.0 }, // 0x0.004p-14 (smallest subnormal)
		{ 17, -0h0001, -0.0 },
		{ 18, 0h03FF, 0.0 }, // 0x0.ffcp-14 (largest subnormal)
		{ 19, -0h03FF, -0.0 },

		{ 20, 0hC809, -8 }, // -0x1.024p+3
		{ 21, 0h4458, 4 }, // 0x1.16p+2
	}

	for d, i in data {
		assert(i == d.i)
		r = trunc_f16(d.v)
		tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(%h) -> %h != %h", i, #procedure, d.v, r, d.e))
	}

	v = SNAN_F16
	r = trunc_f16(v)
	tc.expect(t, is_nan_f16(r), fmt.tprintf("%s(%f) -> %f != NaN", #procedure, v, r))

	v = QNAN_F16
	r = trunc_f16(v)
	tc.expect(t, is_nan_f16(r), fmt.tprintf("%s(%f) -> %f != NaN", #procedure, v, r))
}

@test
test_trunc_f32 :: proc(t: ^testing.T) {

	using math

	r, v: f32

	Datum :: struct {
		i: int,
		v: f32,
		e: f32,
	}
	@static data := []Datum{
		{ 0, 10.5, 10 }, // Issue #1574 fract in linalg/glm is broken
		{ 1, -10.5, -10 },

		{ 2, F32_MAX, F32_MAX },
		{ 3, -F32_MAX, -F32_MAX },
		{ 4, F32_MIN, 0.0 },
		{ 5, -F32_MIN, -0.0 },
		{ 6, 0.0, 0.0 },
		{ 7, -0.0, -0.0 },
		{ 8, 1, 1 },
		{ 9, -1, -1 },
		{ 10, INF_F32, INF_F32 },
		{ 11, NEG_INF_F32, NEG_INF_F32 },

		/* From https://en.wikipedia.org/wiki/Single-precision_floating-point_format */
		{ 12, 0h3F80_0001, 1 }, // 0x1.000002p+0 (smallest > 1)
		{ 13, -0h3F80_0001, -1 },
		{ 14, 0h3F7F_FFFF, 0.0 }, // 0x1.fffffep-1 (largest < 1)
		{ 15, -0h3F7F_FFFF, -0.0 },
		{ 16, 0h0000_0001, 0.0 }, // 0x0.000002p-126 (smallest subnormal)
		{ 17, -0h0000_0001, -0.0 },
		{ 18, 0h007F_FFFF, 0.0 }, // 0x0.fffffep-126 (largest subnormal)
		{ 19, -0h007F_FFFF, -0.0 },

		/* From libc-test src/math/sanity/truncf.h */
		{ 20, 0hC101_11D0, -8 }, // -0x1.0223ap+3
		{ 21, 0h408B_0C34, 4 }, // 0x1.161868p+2
		{ 22, 0hC106_1A5A, -8 }, // -0x1.0c34b4p+3
		{ 23, 0hC0D1_0378, -6 }, // -0x1.a206fp+2
		{ 24, 0h4114_45DE, 9 }, // 0x1.288bbcp+3
		{ 25, 0h3F29_77E8, 0.0 }, // 0x1.52efdp-1
		{ 26, 0hBED0_2E64, -0.0 }, // -0x1.a05cc8p-2
		{ 27, 0h3F0F_CF7D, 0.0 }, // 0x1.1f9efap-1
		{ 28, 0h3F46_2ED8, 0.0 }, // 0x1.8c5dbp-1
		{ 29, 0hBF2D_C375, -0.0 }, // -0x1.5b86eap-1
	}

	for d, i in data {
		assert(i == d.i)
		r = trunc_f32(d.v)
		tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(%h) -> %h != %h", i, #procedure, d.v, r, d.e))
	}

	v = SNAN_F32
	r = trunc_f32(v)
	tc.expect(t, is_nan_f32(r), fmt.tprintf("%s(%f) -> %f != NaN", #procedure, v, r))

	v = QNAN_F32
	r = trunc_f32(v)
	tc.expect(t, is_nan_f32(r), fmt.tprintf("%s(%f) -> %f != NaN", #procedure, v, r))
}

@test
test_trunc_f64 :: proc(t: ^testing.T) {

	using math

	r, v: f64

	Datum :: struct {
		i: int,
		v: f64,
		e: f64,
	}
	data := []Datum{
		{ 0, 10.5, 10 }, // Issue #1574 fract in linalg/glm is broken
		{ 1, -10.5, -10 },

		{ 2, F64_MAX, F64_MAX },
		{ 3, -F64_MAX, -F64_MAX },
		{ 4, F64_MIN, 0.0 },
		{ 5, -F64_MIN, -0.0 },
		{ 6, 0.0, 0.0 },
		{ 7, -0.0, -0.0 },
		{ 8, 1, 1 },
		{ 9, -1, -1 },
		{ 10, INF_F64, INF_F64 },
		{ 11, NEG_INF_F64, NEG_INF_F64 },

		/* From https://en.wikipedia.org/wiki/Double-precision_floating-point_format */
		{ 12, 0h3FF0_0000_0000_0001, 1 }, // 0x1.0000000000001p+0 (smallest > 1)
		{ 13, -0h3FF0_0000_0000_0001, -1 },
		{ 14, 0h3FEF_FFFF_FFFF_FFFF, 0.0 }, // 0x1.fffffffffffffp-1 (largest < 1)
		{ 15, -0h3FEF_FFFF_FFFF_FFFF, -0.0 },
		{ 16, 0h0000_0000_0000_0001, 0.0 }, // 0x0.0000000000001p-1022 (smallest subnormal)
		{ 17, -0h0000_0000_0000_0001, -0.0 },
		{ 18, 0h000F_FFFF_FFFF_FFFF, 0.0 }, // 0x0.fffffffffffffp-1022 (largest subnormal)
		{ 19, -0h000F_FFFF_FFFF_FFFF, -0.0 },

		/* From libc-test src/math/sanity/trunc.h */
		{ 20, 0hC020_2239_F3C6_A8F1, -8 }, // -0x1.02239f3c6a8f1p+3
		{ 21, 0h4011_6186_8E18_BC67, 4 }, // 0x1.161868e18bc67p+2
		{ 22, 0hC020_C34B_3E01_E6E7, -8 }, // -0x1.0c34b3e01e6e7p+3
		{ 23, 0hC01A_206F_0A19_DCC4, -6 }, // -0x1.a206f0a19dcc4p+2
		{ 24, 0h4022_88BB_B0D6_A1E6, 9 }, // 0x1.288bbb0d6a1e6p+3
		{ 25, 0h3FE5_2EFD_0CD8_0497, 0.0 }, // 0x1.52efd0cd80497p-1
		{ 26, 0hBFDA_05CC_7544_81D1, -0.0 }, // -0x1.a05cc754481d1p-2
		{ 27, 0h3FE1_F9EF_9347_45CB, 0.0 }, // 0x1.1f9ef934745cbp-1
		{ 28, 0h3FE8_C5DB_097F_7442, 0.0 }, // 0x1.8c5db097f7442p-1
		{ 29, 0hBFE5_B86E_A811_8A0E, -0.0 }, // -0x1.5b86ea8118a0ep-1
	}

	for d, i in data {
		assert(i == d.i)
		r = trunc_f64(d.v)
		tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(%h) -> %h != %h", i, #procedure, d.v, r, d.e))
	}

	v = SNAN_F64
	r = trunc_f64(v)
	tc.expect(t, is_nan_f64(r), fmt.tprintf("%s(%f) -> %f != NaN", #procedure, v, r))

	v = QNAN_F64
	r = trunc_f64(v)
	tc.expect(t, is_nan_f64(r), fmt.tprintf("%s(%f) -> %f != NaN", #procedure, v, r))
}
