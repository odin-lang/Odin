// Tests "math.odin" in "core:math".
package test_core_math

import "core:math"
import "core:testing"

@test
test_classify_f16 :: proc(t: ^testing.T) {
	r: math.Float_Class

	Datum :: struct {
		i: int,
		v: f16,
		e: math.Float_Class,
	}
	@static data := []Datum{
		{ 0, 1.2, .Normal },
		{ 1, 0h0001, .Subnormal },
		{ 2, 0.0, .Zero },
		{ 3, -0.0, .Neg_Zero },
		{ 4, math.SNAN_F16, .NaN },
		{ 5, math.QNAN_F16, .NaN },
		{ 6, math.INF_F16, .Inf },
		{ 7, math.NEG_INF_F16, .Neg_Inf },
	}

	for d, i in data {
		assert(i == d.i)
		r = math.classify_f16(d.v)
		testing.expectf(t, r == d.e, "%h -> %v != %v", d.v, r, d.e)
	}

	/* Check all subnormals (exponent 0, 10-bit significand non-zero) */
	for i in u16(1)..<0x400 {
		v := transmute(f16)i
		r = math.classify_f16(v)
		e :: math.Float_Class.Subnormal
		testing.expectf(t, r == e, "%h -> %v != %v", v, r, e)
	}
}

@test
test_classify_f32 :: proc(t: ^testing.T) {
	r: math.Float_Class

	Datum :: struct {
		i: int,
		v: f32,
		e: math.Float_Class,
	}
	@static data := []Datum{
		{ 0, 1.2, .Normal },
		{ 1, 0h0000_0001, .Subnormal },
		{ 2, 0.0, .Zero },
		{ 3, -0.0, .Neg_Zero },
		{ 4, math.SNAN_F32, .NaN },
		{ 5, math.QNAN_F32, .NaN },
		{ 6, math.INF_F32, .Inf },
		{ 7, math.NEG_INF_F32, .Neg_Inf },
	}

	for d, i in data {
		assert(i == d.i)
		r = math.classify_f32(d.v)
		testing.expectf(t, r == d.e, "%h -> %v != %v", d.v, r, d.e)
	}
}

@test
test_classify_f64 :: proc(t: ^testing.T) {
	r: math.Float_Class

	Datum :: struct {
		i: int,
		v: f64,
		e: math.Float_Class,
	}
	@static data := []Datum{
		{ 0, 1.2, .Normal },
		{ 1, 0h0000_0000_0000_0001, .Subnormal },
		{ 2, 0.0, .Zero },
		{ 3, -0.0, .Neg_Zero },
		{ 4, math.SNAN_F64, .NaN },
		{ 5, math.QNAN_F64, .NaN },
		{ 6, math.INF_F64, .Inf },
		{ 7, math.NEG_INF_F64, .Neg_Inf },
	}

	for d, i in data {
		assert(i == d.i)
		r = math.classify_f64(d.v)
		testing.expectf(t, r == d.e, "%h -> %v != %v", d.v, r, d.e)
	}
}

@test
test_trunc_f16 :: proc(t: ^testing.T) {
	r, v: f16

	Datum :: struct {
		i: int,
		v: f16,
		e: f16,
	}
	@static data := []Datum{
		{ 0, 10.5, 10 }, // Issue #1574 fract in linalg/glm is broken
		{ 1, -10.5, -10 },

		{ 2, math.F16_MAX, math.F16_MAX },
		{ 3, -math.F16_MAX, -math.F16_MAX },
		{ 4, math.F16_MIN, 0.0 },
		{ 5, -math.F16_MIN, -0.0 },
		{ 6, 0.0, 0.0 },
		{ 7, -0.0, -0.0 },
		{ 8, 1, 1 },
		{ 9, -1, -1 },
		{ 10, math.INF_F16, math.INF_F16 },
		{ 11, math.NEG_INF_F16, math.NEG_INF_F16 },

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
		r = math.trunc_f16(d.v)
		testing.expectf(t, r == d.e, "%h -> %h != %h", d.v, r, d.e)
	}

	v = math.SNAN_F16
	r = math.trunc_f16(v)
	testing.expectf(t, math.is_nan_f16(r), "%f != NaN", v, r)

	v = math.QNAN_F16
	r = math.trunc_f16(v)
	testing.expectf(t, math.is_nan_f16(r), "%f != NaN", v, r)
}

@test
test_trunc_f32 :: proc(t: ^testing.T) {
	r, v: f32

	Datum :: struct {
		i: int,
		v: f32,
		e: f32,
	}
	@static data := []Datum{
		{ 0, 10.5, 10 }, // Issue #1574 fract in linalg/glm is broken
		{ 1, -10.5, -10 },

		{ 2, math.F32_MAX, math.F32_MAX },
		{ 3, -math.F32_MAX, -math.F32_MAX },
		{ 4, math.F32_MIN, 0.0 },
		{ 5, -math.F32_MIN, -0.0 },
		{ 6, 0.0, 0.0 },
		{ 7, -0.0, -0.0 },
		{ 8, 1, 1 },
		{ 9, -1, -1 },
		{ 10, math.INF_F32, math.INF_F32 },
		{ 11, math.NEG_INF_F32, math.NEG_INF_F32 },

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
		r = math.trunc_f32(d.v)
		testing.expectf(t, r == d.e, "%h -> %h != %h", d.v, r, d.e)
	}

	v = math.SNAN_F32
	r = math.trunc_f32(v)
	testing.expectf(t, math.is_nan_f32(r), "%f -> %f != NaN", v, r)

	v = math.QNAN_F32
	r = math.trunc_f32(v)
	testing.expectf(t, math.is_nan_f32(r), "%f -> %f != NaN", v, r)
}

@test
test_trunc_f64 :: proc(t: ^testing.T) {
	r, v: f64

	Datum :: struct {
		i: int,
		v: f64,
		e: f64,
	}
	data := []Datum{
		{ 0, 10.5, 10 }, // Issue #1574 fract in linalg/glm is broken
		{ 1, -10.5, -10 },

		{ 2, math.F64_MAX, math.F64_MAX },
		{ 3, -math.F64_MAX, -math.F64_MAX },
		{ 4, math.F64_MIN, 0.0 },
		{ 5, -math.F64_MIN, -0.0 },
		{ 6, 0.0, 0.0 },
		{ 7, -0.0, -0.0 },
		{ 8, 1, 1 },
		{ 9, -1, -1 },
		{ 10, math.INF_F64, math.INF_F64 },
		{ 11, math.NEG_INF_F64, math.NEG_INF_F64 },

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
		r = math.trunc_f64(d.v)
		testing.expectf(t, r == d.e, "%h -> %h != %h", d.v, r, d.e)
	}

	v = math.SNAN_F64
	r = math.trunc_f64(v)
	testing.expectf(t, math.is_nan_f64(r), "%f -> %f != NaN", v, r)

	v = math.QNAN_F64
	r = math.trunc_f64(v)
	testing.expectf(t, math.is_nan_f64(r), "%f -> %f != NaN", v, r)
}

@test
test_round_f16 :: proc(t: ^testing.T) {
	r, v: f16

	Datum :: struct {
		i: int,
		v: f16,
		e: f16,
	}
	@static data := []Datum{
		{ 0, 10.5, 11 },
		{ 1, -10.5, -11 },

		{ 2, math.F16_MAX, math.F16_MAX },
		{ 3, -math.F16_MAX, -math.F16_MAX },
		{ 4, math.F16_MIN, 0.0 },
		{ 5, -math.F16_MIN, -0.0 },
		{ 6, 0.0, 0.0 },
		{ 7, -0.0, -0.0 },
		{ 8, 1, 1 },
		{ 9, -1, -1 },
		{ 10, math.INF_F16, math.INF_F16 },
		{ 11, math.NEG_INF_F16, math.NEG_INF_F16 },

		/* From https://en.wikipedia.org/wiki/Half-precision_floating-point_format */
		{ 12, 0h3C01, 1 }, // 0x1.004p+0 (smallest > 1)
		{ 13, -0h3C01, -1 },
		{ 14, 0h3BFF, 1 }, // 0x1.ffcp-1 (largest < 1)
		{ 15, -0h3BFF, -1 },
		{ 16, 0h0001, 0.0 }, // 0x0.004p-14 (smallest subnormal)
		{ 17, -0h0001, -0.0 },
		{ 18, 0h03FF, 0.0 }, // 0x0.ffcp-14 (largest subnormal)
		{ 19, -0h03FF, -0.0 },

		{ 20, 0hC809, -8 }, // -0x1.024p+3
		{ 21, 0h4458, 4 }, // 0x1.16p+2
	}

	for d, i in data {
		assert(i == d.i)
		r = math.round_f16(d.v)
		testing.expectf(t, r == d.e, "%h -> %h != %h", d.v, r, d.e)
	}

	v = math.SNAN_F16
	r = math.round_f16(v)
	testing.expectf(t, math.is_nan_f16(r), "%f -> %f != NaN", v, r)

	v = math.QNAN_F16
	r = math.round_f16(v)
	testing.expectf(t, math.is_nan_f16(r), "%f -> %f != NaN", v, r)
}

@test
test_round_f32 :: proc(t: ^testing.T) {
	r, v: f32

	Datum :: struct {
		i: int,
		v: f32,
		e: f32,
	}
	@static data := []Datum{
		{ 0, 10.5, 11 },
		{ 1, -10.5, -11 },

		{ 2, math.F32_MAX, math.F32_MAX },
		{ 3, -math.F32_MAX, -math.F32_MAX },
		{ 4, math.F32_MIN, 0.0 },
		{ 5, -math.F32_MIN, -0.0 },
		{ 6, 0.0, 0.0 },
		{ 7, -0.0, -0.0 },
		{ 8, 1, 1 },
		{ 9, -1, -1 },
		{ 10, math.INF_F32, math.INF_F32 },
		{ 11, math.NEG_INF_F32, math.NEG_INF_F32 },

		/* From https://en.wikipedia.org/wiki/Single-precision_floating-point_format */
		{ 12, 0h3F80_0001, 1 }, // 0x1.000002p+0 (smallest > 1)
		{ 13, -0h3F80_0001, -1 },
		{ 14, 0h3F7F_FFFF, 1 }, // 0x1.fffffep-1 (largest < 1)
		{ 15, -0h3F7F_FFFF, -1 },
		{ 16, 0h0000_0001, 0.0 }, // 0x0.000002p-126 (smallest subnormal)
		{ 17, -0h0000_0001, -0.0 },
		{ 18, 0h007F_FFFF, 0.0 }, // 0x0.fffffep-126 (largest subnormal)
		{ 19, -0h007F_FFFF, -0.0 },

		/* From libc-test src/math/sanity/roundf.h */
		{ 20, 0hC101_11D0, -8 }, // -0x1.0223ap+3
		{ 21, 0h408B_0C34, 4 }, // 0x1.161868p+2
		{ 22, 0hC106_1A5A, -8 }, // -0x1.0c34b4p+3
		{ 23, 0hC0D1_0378, -7 }, // -0x1.a206fp+2
		{ 24, 0h4114_45DE, 9 }, // 0x1.288bbcp+3
		{ 25, 0h3F29_77E8, 1.0 }, // 0x1.52efdp-1
		{ 26, 0hBED0_2E64, -0.0 }, // -0x1.a05cc8p-2
		{ 27, 0h3F0F_CF7D, 1.0 }, // 0x1.1f9efap-1
		{ 28, 0h3F46_2ED8, 1.0 }, // 0x1.8c5dbp-1
		{ 29, 0hBF2D_C375, -1.0 }, // -0x1.5b86eap-1
	}

	for d, i in data {
		assert(i == d.i)
		r = math.round_f32(d.v)
		testing.expectf(t, r == d.e, "%h -> %h != %h", i, d.v, r, d.e)
	}

	v = math.SNAN_F32
	r = math.round_f32(v)
	testing.expectf(t, math.is_nan_f32(r), "%f -> %f != NaN", v, r)

	v = math.QNAN_F32
	r = math.round_f32(v)
	testing.expectf(t, math.is_nan_f32(r), "%f -> %f != NaN", v, r)
}

@test
test_round_f64 :: proc(t: ^testing.T) {
	r, v: f64

	Datum :: struct {
		i: int,
		v: f64,
		e: f64,
	}
	data := []Datum{
		{ 0, 10.5, 11 }, // Issue #1574 fract in linalg/glm is broken
		{ 1, -10.5, -11 },

		{ 2, math.F64_MAX, math.F64_MAX },
		{ 3, -math.F64_MAX, -math.F64_MAX },
		{ 4, math.F64_MIN, 0.0 },
		{ 5, -math.F64_MIN, -0.0 },
		{ 6, 0.0, 0.0 },
		{ 7, -0.0, -0.0 },
		{ 8, 1, 1 },
		{ 9, -1, -1 },
		{ 10, math.INF_F64, math.INF_F64 },
		{ 11, math.NEG_INF_F64, math.NEG_INF_F64 },

		/* From https://en.wikipedia.org/wiki/Double-precision_floating-point_format */
		{ 12, 0h3FF0_0000_0000_0001, 1 }, // 0x1.0000000000001p+0 (smallest > 1)
		{ 13, -0h3FF0_0000_0000_0001, -1 },
		{ 14, 0h3FEF_FFFF_FFFF_FFFF, 1 }, // 0x1.fffffffffffffp-1 (largest < 1)
		{ 15, -0h3FEF_FFFF_FFFF_FFFF, -1 },
		{ 16, 0h0000_0000_0000_0001, 0.0 }, // 0x0.0000000000001p-1022 (smallest subnormal)
		{ 17, -0h0000_0000_0000_0001, -0.0 },
		{ 18, 0h000F_FFFF_FFFF_FFFF, 0.0 }, // 0x0.fffffffffffffp-1022 (largest subnormal)
		{ 19, -0h000F_FFFF_FFFF_FFFF, -0.0 },

		/* From libc-test src/math/sanity/round.h */
		{ 20, 0hC020_2239_F3C6_A8F1, -8 }, // -0x1.02239f3c6a8f1p+3
		{ 21, 0h4011_6186_8E18_BC67, 4 }, // 0x1.161868e18bc67p+2
		{ 22, 0hC020_C34B_3E01_E6E7, -8 }, // -0x1.0c34b3e01e6e7p+3
		{ 23, 0hC01A_206F_0A19_DCC4, -7 }, // -0x1.a206f0a19dcc4p+2
		{ 24, 0h4022_88BB_B0D6_A1E6, 9 }, // 0x1.288bbb0d6a1e6p+3
		{ 25, 0h3FE5_2EFD_0CD8_0497, 1.0 }, // 0x1.52efd0cd80497p-1
		{ 26, 0hBFDA_05CC_7544_81D1, -0.0 }, // -0x1.a05cc754481d1p-2
		{ 27, 0h3FE1_F9EF_9347_45CB, 1.0 }, // 0x1.1f9ef934745cbp-1
		{ 28, 0h3FE8_C5DB_097F_7442, 1.0 }, // 0x1.8c5db097f7442p-1
		{ 29, 0hBFE5_B86E_A811_8A0E, -1.0 }, // -0x1.5b86ea8118a0ep-1
	}

	for d, i in data {
		assert(i == d.i)
		r = math.round_f64(d.v)
		testing.expectf(t, r == d.e, "%h -> %h != %h", d.v, r, d.e)
	}

	v = math.SNAN_F64
	r = math.round_f64(v)
	testing.expectf(t, math.is_nan_f64(r), "%f -> %f != NaN", v, r)

	v = math.QNAN_F64
	r = math.round_f64(v)
	testing.expectf(t, math.is_nan_f64(r), "%f -> %f != NaN", v, r)
}


vf := []f64{
	4.9790119248836735e+00,
	7.7388724745781045e+00,
	-2.7688005719200159e-01,
	-5.0106036182710749e+00,
	9.6362937071984173e+00,
	2.9263772392439646e+00,
	5.2290834314593066e+00,
	2.7279399104360102e+00,
	1.8253080916808550e+00,
	-8.6859247685756013e+00,
}

// The expected results below were computed by the high precision calculators at https://keisan.casio.com/.
acos := []f64{
	1.0496193546107222142571536e+00,
	6.8584012813664425171660692e-01,
	1.5984878714577160325521819e+00,
	2.0956199361475859327461799e+00,
	2.7053008467824138592616927e-01,
	1.2738121680361776018155625e+00,
	1.0205369421140629186287407e+00,
	1.2945003481781246062157835e+00,
	1.3872364345374451433846657e+00,
	2.6231510803970463967294145e+00,
}
acosh := []f64{
	2.4743347004159012494457618e+00,
	2.8576385344292769649802701e+00,
	7.2796961502981066190593175e-01,
	2.4796794418831451156471977e+00,
	3.0552020742306061857212962e+00,
	2.044238592688586588942468e+00,
	2.5158701513104513595766636e+00,
	1.99050839282411638174299e+00,
	1.6988625798424034227205445e+00,
	2.9611454842470387925531875e+00,
}
asin := []f64{
	5.2117697218417440497416805e-01,
	8.8495619865825236751471477e-01,
	-02.769154466281941332086016e-02,
	-5.2482360935268931351485822e-01,
	1.3002662421166552333051524e+00,
	2.9698415875871901741575922e-01,
	5.5025938468083370060258102e-01,
	2.7629597861677201301553823e-01,
	1.83559892257451475846656e-01,
	-1.0523547536021497774980928e+00,
}
asinh := []f64{
	2.3083139124923523427628243e+00,
	2.743551594301593620039021e+00,
	-2.7345908534880091229413487e-01,
	-2.3145157644718338650499085e+00,
	2.9613652154015058521951083e+00,
	1.7949041616585821933067568e+00,
	2.3564032905983506405561554e+00,
	1.7287118790768438878045346e+00,
	1.3626658083714826013073193e+00,
	-2.8581483626513914445234004e+00,
}
atan := []f64{
	1.372590262129621651920085e+00,
	1.442290609645298083020664e+00,
	-2.7011324359471758245192595e-01,
	-1.3738077684543379452781531e+00,
	1.4673921193587666049154681e+00,
	1.2415173565870168649117764e+00,
	1.3818396865615168979966498e+00,
	1.2194305844639670701091426e+00,
	1.0696031952318783760193244e+00,
	-1.4561721938838084990898679e+00,
}
atanh := []f64{
	5.4651163712251938116878204e-01,
	1.0299474112843111224914709e+00,
	-2.7695084420740135145234906e-02,
	-5.5072096119207195480202529e-01,
	1.9943940993171843235906642e+00,
	3.01448604578089708203017e-01,
	5.8033427206942188834370595e-01,
	2.7987997499441511013958297e-01,
	1.8459947964298794318714228e-01,
	-1.3273186910532645867272502e+00,
}
atan2 := []f64{
	1.1088291730037004444527075e+00,
	9.1218183188715804018797795e-01,
	1.5984772603216203736068915e+00,
	2.0352918654092086637227327e+00,
	8.0391819139044720267356014e-01,
	1.2861075249894661588866752e+00,
	1.0889904479131695712182587e+00,
	1.3044821793397925293797357e+00,
	1.3902530903455392306872261e+00,
	2.2859857424479142655411058e+00,
}
cos := []f64{
	2.634752140995199110787593e-01,
	1.148551260848219865642039e-01,
	9.6191297325640768154550453e-01,
	2.938141150061714816890637e-01,
	-9.777138189897924126294461e-01,
	-9.7693041344303219127199518e-01,
	4.940088096948647263961162e-01,
	-9.1565869021018925545016502e-01,
	-2.517729313893103197176091e-01,
	-7.39241351595676573201918e-01,
}

// Results for 1e5 * Pi + vf[i]
cosLarge := []f64{
	2.634752141185559426744e-01,
	1.14855126055543100712e-01,
	9.61912973266488928113e-01,
	2.9381411499556122552e-01,
	-9.777138189880161924641e-01,
	-9.76930413445147608049e-01,
	4.940088097314976789841e-01,
	-9.15658690217517835002e-01,
	-2.51772931436786954751e-01,
	-7.3924135157173099849e-01,
}

cosh := []f64{
	7.2668796942212842775517446e+01,
	1.1479413465659254502011135e+03,
	1.0385767908766418550935495e+00,
	7.5000957789658051428857788e+01,
	7.655246669605357888468613e+03,
	9.3567491758321272072888257e+00,
	9.331351599270605471131735e+01,
	7.6833430994624643209296404e+00,
	3.1829371625150718153881164e+00,
	2.9595059261916188501640911e+03,
}

sin := []f64{
	-9.6466616586009283766724726e-01,
	9.9338225271646545763467022e-01,
	-2.7335587039794393342449301e-01,
	9.5586257685042792878173752e-01,
	-2.099421066779969164496634e-01,
	2.135578780799860532750616e-01,
	-8.694568971167362743327708e-01,
	4.019566681155577786649878e-01,
	9.6778633541687993721617774e-01,
	-6.734405869050344734943028e-01,
}

// Results for 1e5 * Pi + vf[i]
sinLarge := []f64{
	-9.646661658548936063912e-01,
	9.933822527198506903752e-01,
	-2.7335587036246899796e-01,
	9.55862576853689321268e-01,
	-2.099421066862688873691e-01,
	2.13557878070308981163e-01,
	-8.694568970959221300497e-01,
	4.01956668098863248917e-01,
	9.67786335404528727927e-01,
	-6.7344058693131973066e-01,
}
sinh := []f64{
	7.2661916084208532301448439e+01,
	1.1479409110035194500526446e+03,
	-2.8043136512812518927312641e-01,
	-7.499429091181587232835164e+01,
	7.6552466042906758523925934e+03,
	9.3031583421672014313789064e+00,
	9.330815755828109072810322e+01,
	7.6179893137269146407361477e+00,
	3.021769180549615819524392e+00,
	-2.95950575724449499189888e+03,
}
sqrt := []f64{
	2.2313699659365484748756904e+00,
	2.7818829009464263511285458e+00,
	5.2619393496314796848143251e-01,
	2.2384377628763938724244104e+00,
	3.1042380236055381099288487e+00,
	1.7106657298385224403917771e+00,
	2.286718922705479046148059e+00,
	1.6516476350711159636222979e+00,
	1.3510396336454586262419247e+00,
	2.9471892997524949215723329e+00,
}
tan := []f64{
	-3.661316565040227801781974e+00,
	8.64900232648597589369854e+00,
	-2.8417941955033612725238097e-01,
	3.253290185974728640827156e+00,
	2.147275640380293804770778e-01,
	-2.18600910711067004921551e-01,
	-1.760002817872367935518928e+00,
	-4.389808914752818126249079e-01,
	-3.843885560201130679995041e+00,
	9.10988793377685105753416e-01,
}

// Results for 1e5 * Pi + vf[i]
tanLarge := []f64{
	-3.66131656475596512705e+00,
	8.6490023287202547927e+00,
	-2.841794195104782406e-01,
	3.2532901861033120983e+00,
	2.14727564046880001365e-01,
	-2.18600910700688062874e-01,
	-1.760002817699722747043e+00,
	-4.38980891453536115952e-01,
	-3.84388555942723509071e+00,
	9.1098879344275101051e-01,
}
tanh := []f64{
	9.9990531206936338549262119e-01,
	9.9999962057085294197613294e-01,
	-2.7001505097318677233756845e-01,
	-9.9991110943061718603541401e-01,
	9.9999999146798465745022007e-01,
	9.9427249436125236705001048e-01,
	9.9994257600983138572705076e-01,
	9.9149409509772875982054701e-01,
	9.4936501296239685514466577e-01,
	-9.9999994291374030946055701e-01,
}

NaN :: 0h7fff_ffff_ffff_ffff
Pi  :: 0h4009_21fb_5444_2d18

// arguments and expected results for special cases
vfacos_sc := []f64{
	-Pi,
	1,
	Pi,
	NaN,
}
acos_sc := []f64{
	NaN,
	0,
	NaN,
	NaN,
}

vfacosh_sc := []f64{
	math.inf_f64(-1),
	0.5,
	1,
	math.inf_f64(1),
	NaN,
}
acosh_sc := []f64{
	NaN,
	NaN,
	0,
	math.inf_f64(1),
	NaN,
}

vfasin_sc := []f64{
	-Pi,
	math.copy_sign_f64(0, -1),
	0,
	Pi,
	NaN,
}
asin_sc := []f64{
	NaN,
	math.copy_sign_f64(0, -1),
	0,
	NaN,
	NaN,
}

vfasinh_sc := []f64{
	math.inf_f64(-1),
	math.copy_sign_f64(0, -1),
	0,
	math.inf_f64(1),
	NaN,
}
asinh_sc := []f64{
	math.inf_f64(-1),
	math.copy_sign_f64(0, -1),
	0,
	math.inf_f64(1),
	NaN,
}

vfatan_sc := []f64{
	math.inf_f64(-1),
	math.copy_sign_f64(0, -1),
	0,
	math.inf_f64(1),
	NaN,
}
atan_sc := []f64{
	-Pi / 2,
	math.copy_sign_f64(0, -1),
	0,
	Pi / 2,
	NaN,
}

vfatanh_sc := []f64{
	math.inf_f64(-1),
	-Pi,
	-1,
	math.copy_sign_f64(0, -1),
	0,
	1,
	Pi,
	math.inf_f64(1),
	NaN,
}
atanh_sc := []f64{
	NaN,
	NaN,
	math.inf_f64(-1),
	math.copy_sign_f64(0, -1),
	0,
	math.inf_f64(1),
	NaN,
	NaN,
	NaN,
}
vfatan2_sc := [][2]f64{
	{math.inf_f64(-1), math.inf_f64(-1)},
	{math.inf_f64(-1), -Pi},
	{math.inf_f64(-1), 0},
	{math.inf_f64(-1), +Pi},
	{math.inf_f64(-1), math.inf_f64(1)},
	{math.inf_f64(-1), NaN},
	{-Pi, math.inf_f64(-1)},
	{-Pi, 0},
	{-Pi, math.inf_f64(1)},
	{-Pi, NaN},
	{math.copy_sign_f64(0, -1), math.inf_f64(-1)},
	{math.copy_sign_f64(0, -1), -Pi},
	{math.copy_sign_f64(0, -1), math.copy_sign_f64(0, -1)},
	{math.copy_sign_f64(0, -1), 0},
	{math.copy_sign_f64(0, -1), +Pi},
	{math.copy_sign_f64(0, -1), math.inf_f64(1)},
	{math.copy_sign_f64(0, -1), NaN},
	{0, math.inf_f64(-1)},
	{0, -Pi},
	{0, math.copy_sign_f64(0, -1)},
	{0, 0},
	{0, +Pi},
	{0, math.inf_f64(1)},
	{0, NaN},
	{+Pi, math.inf_f64(-1)},
	{+Pi, 0},
	{+Pi, math.inf_f64(1)},
	{1.0, math.inf_f64(1)},
	{-1.0, math.inf_f64(1)},
	{+Pi, NaN},
	{math.inf_f64(1), math.inf_f64(-1)},
	{math.inf_f64(1), -Pi},
	{math.inf_f64(1), 0},
	{math.inf_f64(1), +Pi},
	{math.inf_f64(1), math.inf_f64(1)},
	{math.inf_f64(1), NaN},
	{NaN, NaN},
}
atan2_sc := []f64{
	-3 * Pi / 4,     // atan2(-Inf, -Inf)
	-Pi / 2,         // atan2(-Inf, -Pi)
	-Pi / 2,         // atan2(-Inf, +0)
	-Pi / 2,         // atan2(-Inf, +Pi)
	-Pi / 4,         // atan2(-Inf, +Inf)
	NaN,           // atan2(-Inf, NaN)
	-Pi,             // atan2(-Pi, -Inf)
	-Pi / 2,         // atan2(-Pi, +0)
	math.copy_sign_f64(0, -1), // atan2(-Pi, Inf)
	NaN,           // atan2(-Pi, NaN)
	-Pi,             // atan2(-0, -Inf)
	-Pi,             // atan2(-0, -Pi)
	-Pi,             // atan2(-0, -0)
	math.copy_sign_f64(0, -1), // atan2(-0, +0)
	math.copy_sign_f64(0, -1), // atan2(-0, +Pi)
	math.copy_sign_f64(0, -1), // atan2(-0, +Inf)
	NaN,           // atan2(-0, NaN)
	Pi,              // atan2(+0, -Inf)
	Pi,              // atan2(+0, -Pi)
	Pi,              // atan2(+0, -0)
	0,               // atan2(+0, +0)
	0,               // atan2(+0, +Pi)
	0,               // atan2(+0, +Inf)
	NaN,           // atan2(+0, NaN)
	Pi,              // atan2(+Pi, -Inf)
	Pi / 2,          // atan2(+Pi, +0)
	0,               // atan2(+Pi, +Inf)
	0,               // atan2(+1, +Inf)
	math.copy_sign_f64(0, -1), // atan2(-1, +Inf)
	NaN,           // atan2(+Pi, NaN)
	3 * Pi / 4,      // atan2(+Inf, -Inf)
	Pi / 2,          // atan2(+Inf, -Pi)
	Pi / 2,          // atan2(+Inf, +0)
	Pi / 2,          // atan2(+Inf, +Pi)
	Pi / 4,          // atan2(+Inf, +Inf)
	NaN,           // atan2(+Inf, NaN)
	NaN,           // atan2(NaN, NaN)
}

vfcbrt_sc := []f64{
	math.inf_f64(-1),
	math.copy_sign_f64(0, -1),
	0,
	math.inf_f64(1),
	NaN,
}
cbrt_sc := []f64{
	math.inf_f64(-1),
	math.copy_sign_f64(0, -1),
	0,
	math.inf_f64(1),
	NaN,
}

vfceil_sc := []f64{
	math.inf_f64(-1),
	math.copy_sign_f64(0, -1),
	0,
	math.inf_f64(1),
	NaN,
}
ceil_sc := []f64{
	math.inf_f64(-1),
	math.copy_sign_f64(0, -1),
	0,
	math.inf_f64(1),
	NaN,
}

vfcopysign_sc := []f64{
	math.inf_f64(-1),
	math.inf_f64(1),
	NaN,
}
copysign_sc := []f64{
	math.inf_f64(-1),
	math.inf_f64(-1),
	NaN,
}

vfcos_sc := []f64{
	math.inf_f64(-1),
	math.inf_f64(1),
	NaN,
}
cos_sc := []f64{
	NaN,
	NaN,
	NaN,
}

vfcosh_sc := []f64{
	math.inf_f64(-1),
	math.copy_sign_f64(0, -1),
	0,
	math.inf_f64(1),
	NaN,
}
cosh_sc := []f64{
	math.inf_f64(1),
	1,
	1,
	math.inf_f64(1),
	NaN,
}


vfsin_sc := []f64{
	math.inf_f64(-1),
	math.copy_sign_f64(0, -1),
	0,
	math.inf_f64(1),
	NaN,
}
sin_sc := []f64{
	NaN,
	math.copy_sign_f64(0, -1),
	0,
	NaN,
	NaN,
}

vfsinh_sc := []f64{
	math.inf_f64(-1),
	math.copy_sign_f64(0, -1),
	0,
	math.inf_f64(1),
	NaN,
}
sinh_sc := []f64{
	math.inf_f64(-1),
	math.copy_sign_f64(0, -1),
	0,
	math.inf_f64(1),
	NaN,
}

vftanh_sc := []f64{
	math.inf_f64(-1),
	math.copy_sign_f64(0, -1),
	0,
	math.inf_f64(1),
	NaN,
}
tanh_sc := []f64{
	-1,
	math.copy_sign_f64(0, -1),
	0,
	1,
	NaN,
}


tolerance :: proc(a, b, e: f64) -> bool {
	// Multiplying by e here can underflow denormal values to zero.
	// Check a==b so that at least if a and b are small and identical
	// we say they match.
	if a == b {
		return true
	}
	e := e
	d := a - b
	if d < 0 {
		d = -d
	}

	// note: b is correct (expected) value, a is actual value.
	// make error tolerance a fraction of b, not a.
	if b != 0 {
		e = e * b
		if e < 0 {
			e = -e
		}
	}
	return d < e
}
close :: proc(t: ^testing.T, a, b: f64, loc := #caller_location) -> bool {
	ok := tolerance(a, b, 1e-9)
	testing.expectf(t, ok, "%.15g is not close to %.15g", a, b, loc=loc)
	return ok
}
veryclose :: proc(t: ^testing.T, a, b: f64, loc := #caller_location) -> bool {
	ok := tolerance(a, b, 4e-14)
	testing.expectf(t, ok, "%.15g is not veryclose to %.15g", a, b, loc=loc)
	return ok
}
soclose :: proc(t: ^testing.T, a, b, e: f64, loc := #caller_location) -> bool {
	ok := tolerance(a, b, e)
	testing.expectf(t, ok, "%.15g is not soclose to %.15g", a, b, loc=loc)
	return ok
}
alike :: proc(t: ^testing.T, a, b: f64, loc := #caller_location) -> bool {
	ok := false
	switch {
	case math.is_nan(a) && math.is_nan(b):
		ok = true
	case a == b:
		ok = math.signbit(a) == math.signbit(b)
	}
	testing.expectf(t, ok, "%.15g is not alike to %.15g", a, b, loc=loc)
	return ok
}

@test
test_nan32 :: proc(t: ^testing.T) {
	float32 := f32(NaN)
	equal := float32 == float32
	testing.expectf(t, !equal, "float32(NaN) is %.15g, expected NaN", float32)
}

@test
test_nan64 :: proc(t: ^testing.T) {
	float64 := NaN
	equal := float64 == float64
	testing.expectf(t, !equal, "NaN returns %.15g, expected NaN", float64)
}

@test
test_acos :: proc(t: ^testing.T) {
	for _, i in vf {
		a := vf[i] / 10
		f := math.acos(a)
		testing.expectf(t, close(t, acos[i], f), "math.acos(%.15g) = %.15g, want %.15g", a, f, acos[i])
	}
	for _, i in vfacos_sc {
		f := math.acos(vfacos_sc[i])
		testing.expectf(t, alike(t, acos_sc[i], f), "math.acos(%.15g) = %.15g, want %.15g", vfacos_sc[i], f, acos_sc[i])
	}
}

@test
test_acosh :: proc(t: ^testing.T) {
	for _, i in vf {
		a := 1 + abs(vf[i])
		f := math.acosh(a)
		testing.expectf(t, veryclose(t, acosh[i], f), "math.acosh(%.15g) = %.15g, want %.15g", a, f, acosh[i])
	}
	for _, i in vfacosh_sc {
		f := math.acosh(vfacosh_sc[i])
		testing.expectf(t, alike(t, acosh_sc[i], f), "math.acosh(%.15g) = %.15g, want %.15g", vfacosh_sc[i], f, acosh_sc[i])
	}
}

@test
test_asin :: proc(t: ^testing.T) {
	for _, i in vf {
		a := vf[i] / 10
		f := math.asin(a)
		testing.expectf(t, veryclose(t, asin[i], f), "math.asin(%.15g) = %.15g, want %.15g", a, f, asin[i])
	}
	for _, i in vfasin_sc {
		f := math.asin(vfasin_sc[i])
		testing.expectf(t, alike(t, asin_sc[i], f), "math.asin(%.15g) = %.15g, want %.15g", vfasin_sc[i], f, asin_sc[i])
	}
}

@test
test_asinh :: proc(t: ^testing.T) {
	for _, i in vf {
		f := math.asinh(vf[i])
		testing.expectf(t, veryclose(t, asinh[i], f), "math.asinh(%.15g) = %.15g, want %.15g", vf[i], f, asinh[i])
	}
	for _, i in vfasinh_sc {
		f := math.asinh(vfasinh_sc[i])
		testing.expectf(t, alike(t, asinh_sc[i], f), "math.asinh(%.15g) = %.15g, want %.15g", vfasinh_sc[i], f, asinh_sc[i])
	}
}

@test
test_atan :: proc(t: ^testing.T) {
	for _, i in vf {
		f := math.atan(vf[i])
		testing.expectf(t, veryclose(t, atan[i], f), "math.atan(%.15g) = %.15g, want %.15g", vf[i], f, atan[i])
	}
	for _, i in vfatan_sc {
		f := math.atan(vfatan_sc[i])
		testing.expectf(t, alike(t, atan_sc[i], f), "math.atan(%.15g) = %.15g, want %.15g", vfatan_sc[i], f, atan_sc[i])
	}
}

@test
test_atanh :: proc(t: ^testing.T) {
	for _, i in vf {
		a := vf[i] / 10
		f := math.atanh(a)
		testing.expectf(t, veryclose(t, atanh[i], f), "math.atanh(%.15g) = %.15g, want %.15g", a, f, atanh[i])
	}
	for _, i in vfatanh_sc {
		f := math.atanh(vfatanh_sc[i])
		testing.expectf(t, alike(t, atanh_sc[i], f), "math.atanh(%.15g) = %.15g, want %.15g", vfatanh_sc[i], f, atanh_sc[i])
	}
}

@test
test_atan2 :: proc(t: ^testing.T) {
	for _, i in vf {
		f := math.atan2(10, vf[i])
		testing.expectf(t, veryclose(t, atan2[i], f), "math.atan2(10, %.15g) = %.15g, want %.15g", vf[i], f, atan2[i])
	}
	for _, i in vfatan2_sc {
		f := math.atan2(vfatan2_sc[i][0], vfatan2_sc[i][1])
		testing.expectf(t, alike(t, atan2_sc[i], f), "math.atan2(%.15g, %.15g) = %.15g, want %.15g", vfatan2_sc[i][0], vfatan2_sc[i][1], f, atan2_sc[i])
	}
}

@test
test_cos :: proc(t: ^testing.T) {
	for _, i in vf {
		f := math.cos(vf[i])
		testing.expectf(t, veryclose(t, cos[i], f), "math.cos(%.15g) = %.15g, want %.15g", vf[i], f, cos[i])
	}
	for _, i in vfcos_sc {
		f := math.cos(vfcos_sc[i])
		testing.expectf(t, alike(t, cos_sc[i], f), "math.cos(%.15g) = %.15g, want %.15g", vfcos_sc[i], f, cos_sc[i])
	}
}

@test
test_cosh :: proc(t: ^testing.T) {
	for _, i in vf {
		f := math.cosh(vf[i])
		testing.expectf(t, close(t, cosh[i], f), "math.cosh(%.15g) = %.15g, want %.15g", vf[i], f, cosh[i])
	}
	for _, i in vfcosh_sc {
		f := math.cosh(vfcosh_sc[i])
		testing.expectf(t, alike(t, cosh_sc[i], f), "math.cosh(%.15g) = %.15g, want %.15g", vfcosh_sc[i], f, cosh_sc[i])
	}
}

@test
test_sin :: proc(t: ^testing.T) {
	for _, i in vf {
		f := math.sin(vf[i])
		testing.expectf(t, veryclose(t, sin[i], f), "math.sin(%.15g) = %.15g, want %.15g", vf[i], f, sin[i])
	}
	for _, i in vfsin_sc {
		f := math.sin(vfsin_sc[i])
		testing.expectf(t, alike(t, sin_sc[i], f), "math.sin(%.15g) = %.15g, want %.15g", vfsin_sc[i], f, sin_sc[i])
	}
}

@test
test_sinh :: proc(t: ^testing.T) {
	for _, i in vf {
		f := math.sinh(vf[i])
		testing.expectf(t, close(t, sinh[i], f), "math.sinh(%.15g) = %.15g, want %.15g", vf[i], f, sinh[i])
	}
	for _, i in vfsinh_sc {
		f := math.sinh(vfsinh_sc[i])
		testing.expectf(t, alike(t, sinh_sc[i], f), "math.sinh(%.15g) = %.15g, want %.15g", vfsinh_sc[i], f, sinh_sc[i])
	}
}

@test
test_sqrt :: proc(t: ^testing.T) {
	for _, i in vf {
		a := abs(vf[i])
		f := math.sqrt(a)
		testing.expectf(t, veryclose(t, sqrt[i], f), "math.sqrt(%.15g) = %.15g, want %.15g", a, f, sqrt[i])
	}
}

@test
test_tan :: proc(t: ^testing.T) {
	for _, i in vf {
		f := math.tan(vf[i])
		testing.expectf(t, veryclose(t, tan[i], f), "math.tan(%.15g) = %.15g, want %.15g", vf[i], f, tan[i])
	}
	// same special cases as Sin
	for _, i in vfsin_sc {
		f := math.tan(vfsin_sc[i])
		testing.expectf(t, alike(t, sin_sc[i], f), "math.tan(%.15g) = %.15g, want %.15g", vfsin_sc[i], f, sin_sc[i])
	}
}

@test
test_tanh :: proc(t: ^testing.T) {
	for _, i in vf {
		f := math.tanh(vf[i])
		testing.expectf(t, veryclose(t, tanh[i], f), "math.tanh(%.15g) = %.15g, want %.15g", vf[i], f, tanh[i])
	}
	for _, i in vftanh_sc {
		f := math.tanh(vftanh_sc[i])
		testing.expectf(t, alike(t, tanh_sc[i], f), "math.tanh(%.15g) = %.15g, want %.15g", vftanh_sc[i], f, tanh_sc[i])
	}
}

@test
test_large_cos :: proc(t: ^testing.T) {
	large := f64(1e5 * Pi)
	for _, i in vf {
		f1 := cosLarge[i]
		f2 := math.cos(vf[i] + large)
		testing.expectf(t, close(t, f1, f2), "math.cos(%.15g) = %.15g, want %.15g", vf[i]+large, f2, f1)
	}
}

@test
test_large_sin :: proc(t: ^testing.T) {
	large := f64(1e5 * Pi)
	for _, i in vf {
		f1 := sinLarge[i]
		f2 := math.sin(vf[i] + large)
		testing.expectf(t, close(t, f1, f2), "math.sin(%.15g) = %.15g, want %.15g", vf[i]+large, f2, f1)
	}
}

@test
test_large_tan :: proc(t: ^testing.T) {
	large := f64(1e5 * Pi)
	for _, i in vf {
		f1 := tanLarge[i]
		f2 := math.tan(vf[i] + large)
		testing.expectf(t, close(t, f1, f2), "math.tan(%.15g) = %.15g, want %.15g", vf[i]+large, f2, f1)
	}
}