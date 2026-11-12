// Tests "math.odin" in "core:math".
package test_core_math

import "core:math"
import "core:strconv"
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
		ok = math.sign_bit(a) == math.sign_bit(b)
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

@test
test_count_digits :: proc(t: ^testing.T) {
	_run_test :: proc(t: ^testing.T, $base: int) {
		buf: [64]u8
		for n in 0..<i64(base*base*base) {
			count := math.count_digits_of_base(n, base)
			str := strconv.write_int(buf[:], n, base)
			if !testing.expectf(t,
				len(str) == count,
				"decimal %i in base-%i digit count is %i, does not match length %i of %q",
				n, base, count, len(str), str) {
				break
			}
		}
	}

	_run_test(t, 2)
	_run_test(t, 3)
	_run_test(t, 4)
	_run_test(t, 5)
	_run_test(t, 6)
	_run_test(t, 7)
	_run_test(t, 8)
	_run_test(t, 9)
	_run_test(t, 10)
	_run_test(t, 11)
	_run_test(t, 12)
	_run_test(t, 13)
	_run_test(t, 14)
	_run_test(t, 15)
	_run_test(t, 16)
}

@test
test_nextafter :: proc(t: ^testing.T) {
	// As in C, not Go: nextafter(x, y) returns y when x == y.
	Datum :: struct($F: typeid) {
		x, y, r: F,
	}

	@static f16_data := [?]Datum(f16) {
		{0h3c00, 0h7c42, 0h7e00}, // +1 -> +NaN = +canonical NaN
		{0h3c00, 0hfc42, 0h7e00}, // +1 -> -NaN = +canonical NaN
		{0hbc00, 0h7c42, 0h7e00}, // -1 -> +NaN = +canonical NaN
		{0hbc00, 0hfc42, 0h7e00}, // -1 -> -NaN = +canonical NaN

		{0h7c42, 0h3c00, 0h7e00}, // +NaN -> +1 = +canonical NaN
		{0hfc42, 0h3c00, 0h7e00}, // -NaN -> +1 = +canonical NaN
		{0h7c42, 0hbc00, 0h7e00}, // +NaN -> -1 = +canonical NaN
		{0hfc42, 0hbc00, 0h7e00}, // -NaN -> -1 = +canonical NaN

		{0h0000, 0h8000, 0h8000}, // +0 -> -0 = -0
		{0h0000,     +1, 0h0001}, // +0 -> +1 = +smallest subnormal
		{0h0000,     -1, 0h8001}, // +0 -> -1 = -smallest subnormal

		{0h0000, 0h0000, 0h0000}, // +0 -> +0 = +0
		{0h0000, 0h8000, 0h8000}, // +0 -> -0 = -0
		{0h0000,     +1, 0h0001}, // +0 -> +1 = +smallest subnormal
		{0h0000,     -1, 0h8001}, // +0 -> -1 = -smallest subnormal

		{0h8000, 0h0000, 0h0000}, // -0 -> +0 = +0
		{0h8000, 0h8000, 0h8000}, // -0 -> -0 = -0
		{0h8000,     +1, 0h0001}, // -0 -> +1 = +smallest subnormal
		{0h8000,     -1, 0h8001}, // -0 -> -1 = -smallest subnormal

		{0h0001,     -1, 0h0000}, // +smallest subnormal -> -1 = +0
		{0h8001,     +1, 0h8000}, // -smallest subnormal -> +1 = -0

		{0h03ff,     +1, 0h0400}, // +largest subnormal -> +1 = +smallest normal
		{0h0400,     -1, 0h03ff}, // +smallest normal   -> -1 = +largest subnormal
		{0h83ff,     -1, 0h8400}, // -largest subnormal -> -1 = -smallest normal
		{0h8400,     +1, 0h83ff}, // -smallest normal   -> +1 = -largest subnormal

		{0h3c00,      0, 0h3bff}, // +1 ->  0 = +1-ulp
		{0h3c00,     +1, 0h3c00}, // +1 -> +1 = +1
		{0h3c00,     +2, 0h3c01}, // +1 -> +2 = +1+ulp

		{0hbc00,      0, 0hbbff}, // -1 ->  0 = -1+ulp
		{0hbc00,     -1, 0hbc00}, // -1 -> -1 = -1
		{0hbc00,     -2, 0hbc01}, // -1 -> +2 = -1-ulp

		{0h3c00, 0hfc00, 0h3bff}, // +1 -> -inf = +1-ulp
		{0hbc00, 0h7c00, 0hbbff}, // -1 -> +inf = -1+ulp

		{0h7bff, 0h7c00, 0h7c00}, // +max -> +inf = +inf
		{0h7c00, 0h7c00, 0h7c00}, // +inf -> +inf = +inf
		{0h7c00,      0, 0h7bff}, // +inf -> 0 = +max

		{0hfbff, 0hfc00, 0hfc00}, // -max -> -inf = -inf
		{0hfc00, 0hfc00, 0hfc00}, // -inf -> -inf = -inf
		{0hfc00,      0, 0hfbff}, // -inf -> 0 = -max
	}

	for datum in f16_data {
		r := math.nextafter_f16(datum.x, datum.y)
		testing.expectf(t,
			transmute(u16)r == transmute(u16)datum.r,
			"%h, %h -> %h != %h", datum.x, datum.y, r, datum.r)
	}

	@(static, rodata)
	f32_data := [?]Datum(f32) {
		{      +1, 0h7f842000, 0h7fc00000}, // +1 -> +NaN = +canonical NaN
		{      +1, 0hff842000, 0h7fc00000}, // +1 -> -NaN = +canonical NaN
		{      -1, 0h7f842000, 0h7fc00000}, // -1 -> +NaN = +canonical NaN
		{      -1, 0hff842000, 0h7fc00000}, // -1 -> -NaN = +canonical NaN

		{0h7f842000,         +1, 0h7fc00000}, // +NaN -> +1 = +canonical NaN
		{0hff842000,         +1, 0h7fc00000}, // -NaN -> +1 = +canonical NaN
		{0h7f842000,         -1, 0h7fc00000}, // +NaN -> -1 = +canonical NaN
		{0hff842000,         -1, 0h7fc00000}, // -NaN -> -1 = +canonical NaN

		{0h00000000, 0h80000000, 0h80000000}, // +0 -> -0 = -0
		{0h00000000,         +1, 0h00000001}, // +0 -> +1 = +smallest subnormal
		{0h00000000,         -1, 0h80000001}, // +0 -> -1 = -smallest subnormal

		{0h00000000, 0h00000000, 0h00000000}, // +0 -> +0 = +0
		{0h00000000, 0h80000000, 0h80000000}, // +0 -> -0 = -0
		{0h00000000,         +1, 0h00000001}, // +0 -> +1 = +smallest subnormal
		{0h00000000,         -1, 0h80000001}, // +0 -> -1 = -smallest subnormal

		{0h80000000, 0h00000000, 0h00000000}, // -0 -> +0 = +0
		{0h80000000, 0h80000000, 0h80000000}, // -0 -> -0 = -0
		{0h80000000,         +1, 0h00000001}, // -0 -> +1 = +smallest subnormal
		{0h80000000,         -1, 0h80000001}, // -0 -> -1 = -smallest subnormal

		{0h00000001,         -1, 0h00000000}, // +smallest subnormal -> -1 = +0
		{0h80000001,         +1, 0h80000000}, // -smallest subnormal -> +1 = -0

		{0h03ffffff,     +1, 0h04000000}, // +largest subnormal -> +1 = +smallest normal
		{0h04000000,     -1, 0h03ffffff}, // +smallest normal   -> -1 = +largest subnormal
		{0h83ffffff,     -1, 0h84000000}, // -largest subnormal -> -1 = -smallest normal
		{0h84000000,     +1, 0h83ffffff}, // -smallest normal   -> +1 = -largest subnormal

		{0h3f800000,      0, 0h3f7fffff}, // +1 ->  0 = +1-ulp
		{0h3f800000,     +1, 0h3f800000}, // +1 -> +1 = +1
		{0h3f800000,     +2, 0h3f800001}, // +1 -> +2 = +1+ulp

		{0hbf800000,      0, 0hbf7fffff}, // -1 ->  0 = -1+ulp
		{0hbf800000,     -1, 0hbf800000}, // -1 -> -1 = -1
		{0hbf800000,     -2, 0hbf800001}, // -1 -> +2 = -1-ulp

		{0h3c000000, 0hfc000000, 0h3bffffff}, // +1 -> -inf = +1-ulp
		{0hbc000000, 0h7c000000, 0hbbffffff}, // -1 -> +inf = -1+ulp

		{0h7bffffff, 0h7c000000, 0h7c000000}, // +max -> +inf = +inf
		{0h7c000000, 0h7c000000, 0h7c000000}, // +inf -> +inf = +inf
		{0h7c000000,          0, 0h7bffffff}, // +inf -> 0 = +max

		{0hfbffffff, 0hfc000000, 0hfc000000}, // -max -> -inf = -inf
		{0hfc000000, 0hfc000000, 0hfc000000}, // -inf -> -inf = -inf
		{0hfc000000,          0, 0hfbffffff}, // -inf -> 0 = -max
	}

	for datum in f32_data {
		r := math.nextafter_f32(datum.x, datum.y)
		testing.expectf(t,
			transmute(u32)r == transmute(u32)datum.r,
			"%h, %h -> %h != %h", datum.x, datum.y, r, datum.r)
	}

	@(static, rodata)
	f64_data := [?]Datum(f64) {
		{0h3c00000000000000, 0h7ff4200000000000, 0h7ff8000000000001}, // +1 -> +NaN = +canonical NaN
		{0h3c00000000000000, 0hfff4200000000000, 0h7ff8000000000001}, // +1 -> -NaN = +canonical NaN
		{0hbc00000000000000, 0h7ff4200000000000, 0h7ff8000000000001}, // -1 -> +NaN = +canonical NaN
		{0hbc00000000000000, 0hfff4200000000000, 0h7ff8000000000001}, // -1 -> -NaN = +canonical NaN

		{0h7ff4200000000000, 0h3c00000000000000, 0h7ff8000000000001}, // +NaN -> +1 = +canonical NaN
		{0hfff4200000000000, 0h3c00000000000000, 0h7ff8000000000001}, // -NaN -> +1 = +canonical NaN
		{0h7ff4200000000000, 0hbc00000000000000, 0h7ff8000000000001}, // +NaN -> -1 = +canonical NaN
		{0hfff4200000000000, 0hbc00000000000000, 0h7ff8000000000001}, // -NaN -> -1 = +canonical NaN

		{0h0000000000000000, 0h8000000000000000, 0h8000000000000000}, // +0 -> -0 = -0
		{0h0000000000000000,                 +1, 0h0000000000000001}, // +0 -> +1 = +smallest subnormal
		{0h0000000000000000,                 -1, 0h8000000000000001}, // +0 -> -1 = -smallest subnormal

		{0h0000000000000000, 0h0000000000000000, 0h0000000000000000}, // +0 -> +0 = +0
		{0h0000000000000000, 0h8000000000000000, 0h8000000000000000}, // +0 -> -0 = -0
		{0h0000000000000000,                 +1, 0h0000000000000001}, // +0 -> +1 = +smallest subnormal
		{0h0000000000000000,                 -1, 0h8000000000000001}, // +0 -> -1 = -smallest subnormal

		{0h8000000000000000, 0h0000000000000000, 0h0000000000000000}, // -0 -> +0 = +0
		{0h8000000000000000, 0h8000000000000000, 0h8000000000000000}, // -0 -> -0 = -0
		{0h8000000000000000,                 +1, 0h0000000000000001}, // -0 -> +1 = +smallest subnormal
		{0h8000000000000000,                 -1, 0h8000000000000001}, // -0 -> -1 = -smallest subnormal

		{0h0000000000000001,                 -1, 0h0000000000000000}, // +smallest subnormal -> -1 = +0
		{0h8000000000000001,                 +1, 0h8000000000000000}, // -smallest subnormal -> +1 = -0

		{0h03ffffffffffffff,                 +1, 0h0400000000000000}, // +largest subnormal -> +1 = +smallest normal
		{0h0400000000000000,                 -1, 0h03ffffffffffffff}, // +smallest normal   -> -1 = +largest subnormal
		{0h83ffffffffffffff,                 -1, 0h8400000000000000}, // -largest subnormal -> -1 = -smallest normal
		{0h8400000000000000,                 +1, 0h83ffffffffffffff}, // -smallest normal   -> +1 = -largest subnormal

		{0h3ff0000000000000,                  0, 0h3fefffffffffffff}, // +1 ->  0 = +1-ulp
		{0h3ff0000000000000,                 +1, 0h3ff0000000000000}, // +1 -> +1 = +1
		{0h3ff0000000000000,                 +2, 0h3ff0000000000001}, // +1 -> +2 = +1+ulp

		{0hbff0000000000000,                  0, 0hbfefffffffffffff}, // -1 ->  0 = -1+ulp
		{0hbff0000000000000,                 -1, 0hbff0000000000000}, // -1 -> -1 = -1
		{0hbff0000000000000,                 -2, 0hbff0000000000001}, // -1 -> +2 = -1-ulp

		{0h3ff0000000000000, 0hfff0000000000000, 0h3fefffffffffffff}, // +1 -> -inf = +1-ulp
		{0hbff0000000000000, 0h7ff0000000000000, 0hbfefffffffffffff}, // -1 -> +inf = -1+ulp

		{0h7fefffffffffffff, 0h7ff0000000000000, 0h7ff0000000000000}, // +max -> +inf = +inf
		{0h7ff0000000000000, 0h7ff0000000000000, 0h7ff0000000000000}, // +inf -> +inf = +inf
		{0h7ff0000000000000,                  0, 0h7fefffffffffffff}, // +inf -> 0 = +max

		{0hffefffffffffffff, 0hfff0000000000000, 0hfff0000000000000}, // -max -> -inf = -inf
		{0hfff0000000000000, 0hfff0000000000000, 0hfff0000000000000}, // -inf -> -inf = -inf
		{0hfff0000000000000,                  0, 0hffefffffffffffff}, // -inf -> 0 = -max
	}

	for datum in f64_data {
		r := math.nextafter_f64(datum.x, datum.y)
		testing.expectf(t,
			transmute(u64)r == transmute(u64)datum.r,
			"%h, %h -> %h != %h", datum.x, datum.y, r, datum.r)
	}
}

@test
test_floor_divmod :: proc(t: ^testing.T) {
	for x in -50..=50 {
		for y in -9..=9 {
			if y == 0 {
				continue
			}
			want_div := int(math.floor(f64(x) / f64(y)))
			want_mod := x - want_div*y

			div, mod := math.floor_divmod(x, y)
			testing.expectf(t, div == want_div && mod == want_mod, "floor_divmod(%v, %v) = %v, %v, want %v, %v", x, y, div, mod, want_div, want_mod)
			testing.expectf(t, math.floor_div(x, y) == want_div, "floor_div(%v, %v) = %v, want %v", x, y, math.floor_div(x, y), want_div)
			testing.expectf(t, math.floor_mod(x, y) == want_mod, "floor_mod(%v, %v) = %v, want %v", x, y, math.floor_mod(x, y), want_mod)

			div8, mod8 := math.floor_divmod(i8(x), i8(y))
			testing.expectf(t, int(div8) == want_div && int(mod8) == want_mod, "floor_divmod(i8(%v), i8(%v)) = %v, %v, want %v, %v", x, y, div8, mod8, want_div, want_mod)
		}
	}
}

@test
test_remap :: proc(t: ^testing.T) {
	testing.expect_value(t, math.remap(5.0, 5.0, 5.0, 10.0, 20.0), 15.0)
	testing.expect_value(t, math.remap(f32(5), 5, 5, -20, -10), -15)
	testing.expect_value(t, math.remap(5, 5, 5, 100, 200), 150)
	testing.expect_value(t, math.remap(i8(-3), -3, -3, -50, 50), 0)
	testing.expect_value(t, math.remap_clamped(5.0, 5.0, 5.0, 10.0, 20.0), 15.0)

	testing.expect_value(t, math.remap(2.5, 0.0, 10.0, 100.0, 200.0), 125.0)
	testing.expect_value(t, math.remap(25, 0, 100, 100, 200), 125)
}

@test
test_bias_gain :: proc(t: ^testing.T) {
	testing.expect_value(t, math.bias(0.5, 0.5), 0.5)
	testing.expect_value(t, math.bias(f32(0.5), 0.25), 0.25)
	testing.expect_value(t, math.bias(f16(0), 0.75), 0)
	testing.expect_value(t, math.bias(f64(1), 0.75), 1)
	testing.expectf(t, abs(math.bias(0.5, 0.75) - 0.75) < 1e-15, "bias(0.5, 0.75) = %v, want 0.75", math.bias(0.5, 0.75))

	testing.expect_value(t, math.gain(0.5, 0.25), 0.5)
	testing.expect_value(t, math.gain(f32(0.25), 0.25), 0.125)
}

@test
test_count_digits_limits :: proc(t: ^testing.T) {
	_run_signed :: proc(t: ^testing.T, $T: typeid, $base: int) {
		buf: [72]u8
		for n in ([]T{min(T), min(T) + 1, -1, 0, 1, max(T) - 1, max(T)}) {
			count := math.count_digits_of_base(n, base)
			str := strconv.write_int(buf[:], i64(n), base)
			want := len(str) - 1 if n < 0 else len(str)
			testing.expectf(t, count == want, "%v %v in base-%i digit count is %i, want %i (%q)", typeid_of(T), n, base, count, want, str)
		}
	}
	_run_unsigned :: proc(t: ^testing.T, $T: typeid, $base: int) {
		buf: [72]u8
		for n in ([]T{0, 1, max(T) - 1, max(T)}) {
			count := math.count_digits_of_base(n, base)
			str := strconv.write_uint(buf[:], u64(n), base)
			testing.expectf(t, count == len(str), "%v %v in base-%i digit count is %i, want %i (%q)", typeid_of(T), n, base, count, len(str), str)
		}
	}
	_run :: proc(t: ^testing.T, $base: int) {
		_run_signed(t, i8, base)
		_run_signed(t, i16, base)
		_run_signed(t, i32, base)
		_run_signed(t, i64, base)
		_run_unsigned(t, u8, base)
		_run_unsigned(t, u16, base)
		_run_unsigned(t, u32, base)
		_run_unsigned(t, u64, base)
	}

	_run(t, 2)
	_run(t, 3)
	_run(t, 7)
	_run(t, 8)
	_run(t, 10)
	_run(t, 16)
	_run(t, 32)
}

@test
test_modf :: proc(t: ^testing.T) {
	Datum :: struct {
		x, i, f: f64,
	}
	@(static, rodata)
	data := [?]Datum{
		{0h7ff0_0000_0000_0000, 0h7ff0_0000_0000_0000, 0h0000_0000_0000_0000},
		{0hfff0_0000_0000_0000, 0hfff0_0000_0000_0000, 0h8000_0000_0000_0000},
		{0h0000_0000_0000_0000, 0h0000_0000_0000_0000, 0h0000_0000_0000_0000},
		{0h8000_0000_0000_0000, 0h8000_0000_0000_0000, 0h8000_0000_0000_0000},
		{ 1.5,     1,    0.5},
		{-1.5,    -1,   -0.5},
		{ 0.25,    0,    0.25},
		{-0.25,   -0.0, -0.25},
		{ 3,       3,    0},
		{-3,      -3,   -0.0},
		{ 100.75,  100,  0.75},
	}

	for d in data {
		i, f := math.modf(d.x)
		testing.expectf(t, transmute(u64)i == transmute(u64)d.i && transmute(u64)f == transmute(u64)d.f,
			"modf(%v) = %v, %v, want %v, %v", d.x, i, f, d.i, d.f)

		fi, ff := math.modf(f32(d.x))
		testing.expectf(t, transmute(u32)fi == transmute(u32)f32(d.i) && transmute(u32)ff == transmute(u32)f32(d.f),
			"modf(f32(%v)) = %v, %v, want %v, %v", d.x, fi, ff, d.i, d.f)

		hi, hf := math.modf(f16(d.x))
		testing.expectf(t, transmute(u16)hi == transmute(u16)f16(d.i) && transmute(u16)hf == transmute(u16)f16(d.f),
			"modf(f16(%v)) = %v, %v, want %v, %v", d.x, hi, hf, d.i, d.f)
	}

	ni, nf := math.modf(math.nan_f64())
	testing.expectf(t, math.is_nan(ni) && math.is_nan(nf), "modf(NaN) = %v, %v, want NaN, NaN", ni, nf)
	ni32, nf32 := math.modf(math.nan_f32())
	testing.expectf(t, math.is_nan(ni32) && math.is_nan(nf32), "modf(f32 NaN) = %v, %v, want NaN, NaN", ni32, nf32)
	ni16, nf16 := math.modf(math.nan_f16())
	testing.expectf(t, math.is_nan(ni16) && math.is_nan(nf16), "modf(f16 NaN) = %v, %v, want NaN, NaN", ni16, nf16)
}

@test
test_pow10 :: proc(t: ^testing.T) {
	for n in ([]f64{-7.5, -2.25, -0.5, 0.5, 1.5, 2.5, 3.75}) {
		d := math.pow10(n)
		testing.expectf(t, d == math.pow(f64(10), n), "pow10(%v) = %v, want %v", n, d, math.pow(f64(10), n))
		f := math.pow10(f32(n))
		testing.expectf(t, f == math.pow(f32(10), f32(n)), "pow10(f32(%v)) = %v, want %v", n, f, math.pow(f32(10), f32(n)))
		h := math.pow10(f16(n))
		testing.expectf(t, h == math.pow(f16(10), f16(n)), "pow10(f16(%v)) = %v, want %v", n, h, math.pow(f16(10), f16(n)))
	}

	p := math.pow10(f64(2.5))
	testing.expectf(t, p > 316.2277 && p < 316.2278, "pow10(2.5) = %v, want ~316.22777", p)

	testing.expect_value(t, math.pow10(f64(0)), 1)
	testing.expect_value(t, math.pow10(f64(2)), 100)
	testing.expect_value(t, math.pow10(f64(-1)), 0.1)
	testing.expect_value(t, math.pow10(f32(3)), 1000)
	testing.expect_value(t, math.pow10(f16(-2)), 0.01)

	testing.expect_value(t, math.pow10(f64(309)), math.inf_f64(1))
	testing.expect_value(t, math.pow10(f64(-400)), 0)
	testing.expect_value(t, math.pow10(math.inf_f64(1)), math.inf_f64(1))
	testing.expect_value(t, math.pow10(math.inf_f64(-1)), 0)
	testing.expect_value(t, math.pow10(math.inf_f32(1)), math.inf_f32(1))
	testing.expect_value(t, math.pow10(math.inf_f16(-1)), 0)

	testing.expect(t, math.is_nan(math.pow10(math.nan_f64())), "pow10(NaN) is not NaN")
	testing.expect(t, math.is_nan(math.pow10(math.nan_f32())), "pow10(f32 NaN) is not NaN")
	testing.expect(t, math.is_nan(math.pow10(math.nan_f16())), "pow10(f16 NaN) is not NaN")
}

@test
test_floor_ceil :: proc(t: ^testing.T) {
	Case :: struct {
		x, floor, ceil: f64,
	}
	cases := [?]Case{
		{0, 0, 0},
		{-0.0, -0.0, -0.0},
		{0.5, 0, 1},
		{-0.5, -1, -0.0},
		{1, 1, 1},
		{-1, -1, -1},
		{2.5, 2, 3},
		{-2.5, -3, -2},
		{1e-300, 0, 1},
		{-1e-300, -1, -0.0},
		{4503599627370495.5, 4503599627370495, 4503599627370496},
		{-4503599627370495.5, -4503599627370496, -4503599627370495},
		{1e300, 1e300, 1e300},
		{math.INF_F64, math.INF_F64, math.INF_F64},
		{math.NEG_INF_F64, math.NEG_INF_F64, math.NEG_INF_F64},
		{math.QNAN_F64, math.QNAN_F64, math.QNAN_F64},
	}
	for c in cases {
		f := math.floor(c.x)
		testing.expectf(t, same(f, c.floor), "floor(%v) = %v, want %v", c.x, f, c.floor)
		g := math.ceil(c.x)
		testing.expectf(t, same(g, c.ceil), "ceil(%v) = %v, want %v", c.x, g, c.ceil)
	}

	narrow := [?]Case{
		{0, 0, 0},
		{-0.0, -0.0, -0.0},
		{0.5, 0, 1},
		{-0.5, -1, -0.0},
		{-2.5, -3, -2},
		{511.75, 511, 512},
		{math.INF_F64, math.INF_F64, math.INF_F64},
		{math.NEG_INF_F64, math.NEG_INF_F64, math.NEG_INF_F64},
	}
	for c in narrow {
		f32f, f32c := math.floor(f32(c.x)), math.ceil(f32(c.x))
		testing.expectf(t, same(f32f, f32(c.floor)) && same(f32c, f32(c.ceil)), "floor, ceil(f32(%v)) = %v, %v", c.x, f32f, f32c)
		f16f, f16c := math.floor(f16(c.x)), math.ceil(f16(c.x))
		testing.expectf(t, same(f16f, f16(c.floor)) && same(f16c, f16(c.ceil)), "floor, ceil(f16(%v)) = %v, %v", c.x, f16f, f16c)
	}
	testing.expect(t, math.is_nan(math.floor(math.QNAN_F32)) && math.is_nan(math.ceil(math.QNAN_F32)))
	testing.expect(t, math.is_nan(math.floor(math.QNAN_F16)) && math.is_nan(math.ceil(math.QNAN_F16)))
}

@test
test_copy_sign_sign_bit :: proc(t: ^testing.T) {
	testing.expect(t, same(math.copy_sign(f64(3), -1), f64(-3)))
	testing.expect(t, same(math.copy_sign(f64(-3), 1), f64(3)))
	testing.expect(t, same(math.copy_sign(f64(0), -1), f64(-0.0)))
	testing.expect(t, same(math.copy_sign(f64(-0.0), 0), f64(0)))
	testing.expect(t, same(math.copy_sign(math.INF_F64, -0.0), math.NEG_INF_F64))
	testing.expect(t, same(math.copy_sign(f64(2), math.NEG_INF_F64), f64(-2)))
	testing.expect(t, same(math.copy_sign(f64(2), -math.QNAN_F64), f64(-2)))
	neg_nan := math.copy_sign(math.QNAN_F64, -1)
	testing.expect(t, math.is_nan(neg_nan) && math.sign_bit(neg_nan))
	testing.expect(t, same(math.copy_sign(f32(3), -1), f32(-3)))
	testing.expect(t, same(math.copy_sign(f32(-0.0), 1), f32(0)))
	testing.expect(t, same(math.copy_sign(f16(3), -1), f16(-3)))
	testing.expect(t, same(math.copy_sign(f16(-0.0), 1), f16(0)))

	testing.expect(t, !math.sign_bit(f64(0)))
	testing.expect(t, math.sign_bit(f64(-0.0)))
	testing.expect(t, math.sign_bit(f64(-5e-324)))
	testing.expect(t, !math.sign_bit(math.INF_F64))
	testing.expect(t, math.sign_bit(math.NEG_INF_F64))
	testing.expect(t, !math.sign_bit(f32(0)))
	testing.expect(t, math.sign_bit(f32(-0.0)))
	testing.expect(t, !math.sign_bit(f32(1.401298464324817e-45)))
	testing.expect(t, !math.sign_bit(f16(0)))
	testing.expect(t, math.sign_bit(f16(-0.0)))
	testing.expect(t, math.sign_bit(math.NEG_INF_F16))
}

@test
test_is_nan_is_inf :: proc(t: ^testing.T) {
	testing.expect(t, math.is_nan(math.QNAN_F64))
	testing.expect(t, math.is_nan(math.SNAN_F64))
	testing.expect(t, math.is_nan(math.copy_sign(math.QNAN_F64, -1)))
	testing.expect(t, !math.is_nan(math.INF_F64))
	testing.expect(t, !math.is_nan(f64(math.F64_MAX)))
	testing.expect(t, !math.is_nan(f64(-0.0)))
	testing.expect(t, math.is_nan(math.QNAN_F32))
	testing.expect(t, !math.is_nan(math.INF_F32))
	testing.expect(t, math.is_nan(math.QNAN_F16))
	testing.expect(t, !math.is_nan(math.INF_F16))

	testing.expect(t, math.is_inf(math.INF_F64))
	testing.expect(t, math.is_inf(math.NEG_INF_F64))
	testing.expect(t, math.is_inf(math.INF_F64, 1))
	testing.expect(t, !math.is_inf(math.INF_F64, -1))
	testing.expect(t, math.is_inf(math.NEG_INF_F64, -1))
	testing.expect(t, !math.is_inf(math.NEG_INF_F64, 1))
	testing.expect(t, !math.is_inf(math.QNAN_F64))
	testing.expect(t, !math.is_inf(f64(math.F64_MAX)))
	testing.expect(t, !math.is_inf(f64(0)))
	testing.expect(t, math.is_inf(math.INF_F32, 1))
	testing.expect(t, !math.is_inf(math.INF_F32, -1))
	testing.expect(t, math.is_inf(math.NEG_INF_F32, -1))
	testing.expect(t, !math.is_inf(math.QNAN_F32))
	testing.expect(t, math.is_inf(math.INF_F16, 1))
	testing.expect(t, !math.is_inf(math.NEG_INF_F16, 1))
	testing.expect(t, math.is_inf(math.NEG_INF_F16, -1))
	testing.expect(t, !math.is_inf(f16(65504)))
}

@test
test_ilogb_logb :: proc(t: ^testing.T) {
	Case :: struct {
		x:    f64,
		want: int,
	}
	cases := [?]Case{
		{1, 0},
		{-1, 0},
		{0.75, -1},
		{-8, 3},
		{1023.9, 9},
		{math.F64_MAX, 1023},
		{math.F64_MIN, -1022},
		{2.2250738585072009e-308, -1023},
		{5e-324, -1074},
		{-5e-324, -1074},
	}
	for c in cases {
		i := math.ilogb(c.x)
		testing.expectf(t, i == c.want, "ilogb(%v) = %v, want %v", c.x, i, c.want)
		l := math.logb(c.x)
		testing.expectf(t, same(l, f64(c.want)), "logb(%v) = %v, want %v", c.x, l, c.want)
	}
	testing.expect_value(t, math.ilogb(f64(0)), int(min(i32)))
	testing.expect_value(t, math.ilogb(f64(-0.0)), int(min(i32)))
	testing.expect_value(t, math.ilogb(math.INF_F64), int(max(i32)))
	testing.expect_value(t, math.ilogb(math.NEG_INF_F64), int(max(i32)))
	testing.expect_value(t, math.ilogb(math.QNAN_F64), int(max(i32)))
	testing.expect(t, same(math.logb(f64(0)), math.NEG_INF_F64))
	testing.expect(t, same(math.logb(f64(-0.0)), math.NEG_INF_F64))
	testing.expect(t, same(math.logb(math.NEG_INF_F64), math.INF_F64))
	testing.expect(t, math.is_nan(math.logb(math.QNAN_F64)))

	testing.expect_value(t, math.ilogb(f32(0.75)), -1)
	testing.expect_value(t, math.ilogb(f32(3.4028234663852886e38)), 127)
	testing.expect_value(t, math.ilogb(f32(1.401298464324817e-45)), -149)
	testing.expect_value(t, math.ilogb(f32(0)), int(min(i32)))
	testing.expect(t, same(math.logb(f32(-8)), f32(3)))
	testing.expect(t, same(math.logb(f32(0)), math.NEG_INF_F32))
	testing.expect_value(t, math.ilogb(f16(65504)), 15)
	testing.expect_value(t, math.ilogb(f16(5.960464477539063e-08)), -24)
	testing.expect(t, same(math.logb(f16(0.75)), f16(-1)))
	testing.expect(t, same(math.logb(math.NEG_INF_F16), math.INF_F16))
}

@test
test_normalize :: proc(t: ^testing.T) {
	y, e := math.normalize(f64(5e-324))
	testing.expectf(t, same(y, f64(math.F64_MIN)) && e == -52, "normalize(5e-324) = %v, %v", y, e)
	y, e = math.normalize(f64(-2.2250738585072009e-308))
	testing.expectf(t, same(y, f64(-1.0020841800044862e-292)) && e == -52, "normalize(-2.2250738585072009e-308) = %v, %v", y, e)
	y, e = math.normalize(f64(math.F64_MIN))
	testing.expectf(t, same(y, f64(math.F64_MIN)) && e == 0, "normalize(F64_MIN) = %v, %v", y, e)
	y, e = math.normalize(f64(-3))
	testing.expectf(t, same(y, f64(-3)) && e == 0, "normalize(-3) = %v, %v", y, e)

	y32, e32 := math.normalize(f32(1.401298464324817e-45))
	testing.expectf(t, same(y32, f32(1.1754943508222875e-38)) && e32 == -23, "normalize(f32(1.401298464324817e-45)) = %v, %v", y32, e32)
	y16, e16 := math.normalize(f16(5.960464477539063e-08))
	testing.expectf(t, same(y16, f16(6.103515625e-05)) && e16 == -10, "normalize(f16(5.960464477539063e-08)) = %v, %v", y16, e16)
}

@test
test_exp :: proc(t: ^testing.T) {
	Case :: struct {
		x, want: f64,
	}
	cases := [?]Case{
		{0, 1},
		{-0.0, 1},
		{1, math.E},
		{-1, 0.36787944117144233},
		{0.5, 1.6487212707001282},
		{100, 2.6881171418161356e+43},
		{-700, 9.8596765437597708e-305},
		{709.78, 1.7928227943945155e+308},
		{710, math.INF_F64},
		{-745, 5e-324},
		{-746, 0},
		{math.INF_F64, math.INF_F64},
		{math.NEG_INF_F64, 0},
		{math.QNAN_F64, math.QNAN_F64},
	}
	for c in cases {
		got := math.exp(c.x)
		testing.expectf(t, within_ulps(got, c.want), "exp(%v) = %v, want %v", c.x, got, c.want)
	}
	testing.expect(t, within_ulps(math.exp(f32(1)), f32(math.E)))
	testing.expect(t, same(math.exp(math.NEG_INF_F32), f32(0)))
	testing.expect(t, same(math.exp(f32(89)), math.INF_F32))
	testing.expect(t, within_ulps(math.exp(f16(1)), f16(math.E)))
	testing.expect(t, same(math.exp(f16(12)), math.INF_F16))
}

@test
test_ln :: proc(t: ^testing.T) {
	Case :: struct {
		x, want: f64,
	}
	cases := [?]Case{
		{1, 0},
		{2, math.LN2},
		{10, math.LN10},
		{0.5, -math.LN2},
		{1e-300, -690.77552789821368},
		{5e-324, -744.44007192138122},
		{1e300, 690.77552789821368},
		{0, math.NEG_INF_F64},
		{-0.0, math.NEG_INF_F64},
		{-1, math.QNAN_F64},
		{math.INF_F64, math.INF_F64},
		{math.NEG_INF_F64, math.QNAN_F64},
		{math.QNAN_F64, math.QNAN_F64},
	}
	for c in cases {
		got := math.ln(c.x)
		testing.expectf(t, within_ulps(got, c.want), "ln(%v) = %v, want %v", c.x, got, c.want)
	}
	testing.expect(t, within_ulps(math.ln(f32(2)), f32(math.LN2)))
	testing.expect(t, same(math.ln(f32(0)), math.NEG_INF_F32))
	testing.expect(t, math.is_nan(math.ln(f32(-1))))
	testing.expect(t, within_ulps(math.ln(f16(2)), f16(math.LN2)))
	testing.expect(t, same(math.ln(f16(1)), f16(0)))
}

@test
test_log1p :: proc(t: ^testing.T) {
	Case :: struct {
		x, want: f64,
	}
	cases := [?]Case{
		{0, 0},
		{-0.0, -0.0},
		{1e-10, 9.9999999995000007e-11},
		{-1e-300, -1e-300},
		{-0.5, -math.LN2},
		{1, math.LN2},
		{1e300, 690.77552789821368},
		{-1, math.NEG_INF_F64},
		{-2, math.QNAN_F64},
		{math.INF_F64, math.INF_F64},
		{math.NEG_INF_F64, math.QNAN_F64},
		{math.QNAN_F64, math.QNAN_F64},
	}
	for c in cases {
		got := math.log1p(c.x)
		testing.expectf(t, within_ulps(got, c.want), "log1p(%v) = %v, want %v", c.x, got, c.want)
	}
	testing.expect(t, within_ulps(math.log1p(f32(1)), f32(math.LN2)))
	testing.expect(t, same(math.log1p(f32(-1)), math.NEG_INF_F32))
	testing.expect(t, within_ulps(math.log1p(f16(1)), f16(math.LN2)))
	testing.expect(t, same(math.log1p(f16(-0.0)), f16(-0.0)))
}

@test
test_pow :: proc(t: ^testing.T) {
	Case :: struct {
		x, y, want: f64,
	}
	cases := [?]Case{
		{2, 0.5, math.SQRT_TWO},
		{10, -3, 0.001},
		{2.5, 3.5, 24.705294220065465},
		{1.0000001, 1e7, 2.7182816941320818},
		{-2, 3, -8},
		{-2, -3, -0.125},
		{2, -1074, 5e-324},
		{0.5, -1074, math.INF_F64},
		{math.QNAN_F64, 0, 1},
		{math.QNAN_F64, -0.0, 1},
		{1, math.QNAN_F64, 1},
		{1, math.INF_F64, 1},
		{-1, math.INF_F64, 1},
		{-1, math.NEG_INF_F64, 1},
		{0, -1, math.INF_F64},
		{-0.0, -1, math.NEG_INF_F64},
		{-0.0, -2, math.INF_F64},
		{0, -0.5, math.INF_F64},
		{-0.0, math.NEG_INF_F64, math.INF_F64},
		{-0.0, 3, -0.0},
		{-0.0, 2, 0},
		{-0.0, 0.5, 0},
		{-2, 0.5, math.QNAN_F64},
		{0.5, math.NEG_INF_F64, math.INF_F64},
		{2, math.NEG_INF_F64, 0},
		{0.5, math.INF_F64, 0},
		{2, math.INF_F64, math.INF_F64},
		{math.NEG_INF_F64, -3, -0.0},
		{math.NEG_INF_F64, -2, 0},
		{math.NEG_INF_F64, 3, math.NEG_INF_F64},
		{math.NEG_INF_F64, 2, math.INF_F64},
		{math.INF_F64, -1, 0},
		{math.INF_F64, 0.5, math.INF_F64},
		{math.QNAN_F64, 1, math.QNAN_F64},
		{2, math.QNAN_F64, math.QNAN_F64},
	}
	for c in cases {
		got := math.pow(c.x, c.y)
		testing.expectf(t, within_ulps(got, c.want), "pow(%v, %v) = %v, want %v", c.x, c.y, got, c.want)
	}
	testing.expect(t, within_ulps(math.pow(f32(2), 0.5), f32(math.SQRT_TWO)))
	testing.expect(t, same(math.pow(f32(-0.0), -1), math.NEG_INF_F32))
	testing.expect(t, same(math.pow(f16(2), 10), f16(1024)))
	testing.expect(t, within_ulps(math.pow(f16(2), 0.5), f16(math.SQRT_TWO)))
}

@test
test_erf :: proc(t: ^testing.T) {
	Case :: struct {
		x, want: f64,
	}
	cases := [?]Case{
		{0, 0},
		{-0.0, -0.0},
		{0.1, 0.1124629160182849},
		{0.5, 0.52049987781304652},
		{-1, -0.84270079294971489},
		{3, 0.99997790950300136},
		{6, 1},
		{math.INF_F64, 1},
		{math.NEG_INF_F64, -1},
		{math.QNAN_F64, math.QNAN_F64},
	}
	for c in cases {
		got := math.erf(c.x)
		testing.expectf(t, within_ulps(got, c.want), "erf(%v) = %v, want %v", c.x, got, c.want)
	}
	testing.expect(t, within_ulps(math.erf(f32(0.5)), f32(0.52049987781304652)))
	testing.expect(t, same(math.erf(f32(-0.0)), f32(-0.0)))
	testing.expect(t, within_ulps(math.erf(f16(0.5)), f16(0.52049987781304652)))
	testing.expect(t, same(math.erf(math.NEG_INF_F16), f16(-1)))
}

@test
test_gamma :: proc(t: ^testing.T) {
	Case :: struct {
		x, want: f64,
	}
	cases := [?]Case{
		{0.5, 1.7724538509055161},
		{1, 1},
		{2, 1},
		{5, 24},
		{2.5, 1.329340388179137},
		{10.1, 454760.7514415856},
		{30, 8.8417619937397019e+30},
		{-0.5, -3.5449077018110322},
		{-2.5, -0.9453087204829419},
		{1e-10, 9999999999.4227848},
		{171.6, 1.5858969096672565e+308},
		{172, math.INF_F64},
		{0, math.INF_F64},
		{-0.0, math.NEG_INF_F64},
		{-1, math.QNAN_F64},
		{-2, math.QNAN_F64},
		{math.INF_F64, math.INF_F64},
		{math.NEG_INF_F64, math.QNAN_F64},
		{math.QNAN_F64, math.QNAN_F64},
	}
	for c in cases {
		got := math.gamma(c.x)
		testing.expectf(t, within_ulps(got, c.want), "gamma(%v) = %v, want %v", c.x, got, c.want)
	}
	testing.expect(t, within_ulps(math.gamma(f32(0.5)), f32(1.7724538509055161)))
	testing.expect(t, same(math.gamma(f32(5)), f32(24)))
	testing.expect(t, same(math.gamma(f32(-0.0)), math.NEG_INF_F32))
	testing.expect(t, within_ulps(math.gamma(f16(0.5)), f16(1.7724538509055161)))
	testing.expect(t, same(math.gamma(f16(5)), f16(24)))
}

@test
test_cbrt :: proc(t: ^testing.T) {
	Case :: struct {
		x, want: f64,
	}
	cases := [?]Case{
		{2, 1.2599210498948732},
		{-27, -3},
		{1e300, 1e100},
		{0.001, 0.1},
		{0, 0},
		{-0.0, -0.0},
		{math.INF_F64, math.INF_F64},
		{math.NEG_INF_F64, math.NEG_INF_F64},
		{math.QNAN_F64, math.QNAN_F64},
	}
	for c in cases {
		got := math.cbrt(c.x)
		testing.expectf(t, within_ulps(got, c.want), "cbrt(%v) = %v, want %v", c.x, got, c.want)
	}
	testing.expect(t, within_ulps(math.cbrt(f32(2)), f32(1.2599210498948732)))
	testing.expect(t, same(math.cbrt(f32(-27)), f32(-3)))
	testing.expect(t, same(math.cbrt(f16(-27)), f16(-3)))
	testing.expect(t, same(math.cbrt(f16(-0.0)), f16(-0.0)))
}

@test
test_divmod :: proc(t: ^testing.T) {
	Case :: struct {
		x, y, div, mod: int,
	}
	cases := [?]Case{
		{7, 2, 3, 1},
		{-7, 2, -3, -1},
		{7, -2, -3, 1},
		{-7, -2, 3, -1},
		{6, 3, 2, 0},
		{0, 5, 0, 0},
	}
	for c in cases {
		div, mod := math.divmod(c.x, c.y)
		testing.expectf(t, div == c.div && mod == c.mod, "divmod(%v, %v) = %v, %v, want %v, %v", c.x, c.y, div, mod, c.div, c.mod)
	}
	d8, m8 := math.divmod(i8(-128), 3)
	testing.expectf(t, d8 == -42 && m8 == -2, "divmod(i8(-128), 3) = %v, %v", d8, m8)
	du, mu := math.divmod(u32(4_000_000_001), 10)
	testing.expectf(t, du == 400_000_000 && mu == 1, "divmod(u32(4_000_000_001), 10) = %v, %v", du, mu)
}

@test
test_gcd :: proc(t: ^testing.T) {
	testing.expect_value(t, math.gcd(12, 18), 6)
	testing.expect_value(t, math.gcd(-12, 18), 6)
	testing.expect_value(t, math.gcd(12, -18), 6)
	testing.expect_value(t, math.gcd(-12, -18), 6)
	testing.expect_value(t, math.gcd(17, 5), 1)
	testing.expect_value(t, math.gcd(0, 5), 5)
	testing.expect_value(t, math.gcd(-5, 0), 5)
	testing.expect_value(t, math.gcd(0, 0), 0)
	testing.expect_value(t, math.gcd(i64(1) << 40, i64(3) << 20), i64(1) << 20)
	testing.expect_value(t, math.gcd(u8(255), 51), 51)
}

@test
test_factorial :: proc(t: ^testing.T) {
	LAST :: 20 when size_of(int) == 8 else 12
	want := 1
	for n in 0..=LAST {
		if n > 0 {
			want *= n
		}
		got := math.factorial(n)
		testing.expectf(t, got == want, "factorial(%v) = %v, want %v", n, got, want)
	}
	testing.expect_value(t, math.factorial(12), 479_001_600)
	when size_of(int) == 8 {
		testing.expect_value(t, math.factorial(20), 2_432_902_008_176_640_000)
	}
}

@test
test_step_smoothstep :: proc(t: ^testing.T) {
	testing.expect_value(t, math.step(f64(0.5), 0.25), 0)
	testing.expect_value(t, math.step(f64(0.5), 0.5), 1)
	testing.expect_value(t, math.step(f64(0.5), 0.75), 1)
	testing.expect_value(t, math.step(3, 2), 0)
	testing.expect_value(t, math.step(3, 3), 1)
	testing.expect_value(t, math.smoothstep(f64(0), 1, -1), 0)
	testing.expect_value(t, math.smoothstep(f64(0), 1, 0.25), 0.15625)
	testing.expect_value(t, math.smoothstep(f64(0), 1, 0.5), 0.5)
	testing.expect_value(t, math.smoothstep(f64(0), 1, 2), 1)
	testing.expect_value(t, math.smoothstep(f64(10), 0, 2.5), 0.84375)
	testing.expect_value(t, math.smoothstep(f32(2), 4, 3), 0.5)
}

@test
test_lerp_unlerp_saturate :: proc(t: ^testing.T) {
	testing.expect_value(t, math.lerp(f64(0), 10, f64(0.25)), 2.5)
	testing.expect_value(t, math.lerp(f64(2), 4, f64(0)), 2)
	testing.expect_value(t, math.lerp(f64(2), 4, f64(1)), 4)
	testing.expect_value(t, math.lerp(f64(2), 4, f64(1.5)), 5)
	testing.expect_value(t, math.lerp(f32(-1), 1, f32(0.5)), 0)
	testing.expect_value(t, math.lerp([2]f32{0, 10}, [2]f32{10, 20}, f32(0.5)), [2]f32{5, 15})
	testing.expect_value(t, math.unlerp(f64(0), 10, 2.5), 0.25)
	testing.expect_value(t, math.unlerp(f64(10), 20, 5), -0.5)
	testing.expect_value(t, math.unlerp(f32(2), 4, 4), 1)
	testing.expect_value(t, math.saturate(f64(-0.5)), 0)
	testing.expect_value(t, math.saturate(f64(0.5)), 0.5)
	testing.expect_value(t, math.saturate(f64(1.5)), 1)
	testing.expect_value(t, math.saturate(f32(2)), 1)
}

@test
test_sum_prod_cumsum :: proc(t: ^testing.T) {
	ints := []int{1, 2, 3, 4}
	testing.expect_value(t, math.sum(ints), 10)
	testing.expect_value(t, math.prod(ints), 24)
	testing.expect_value(t, math.sum([]int{}), 0)
	testing.expect_value(t, math.prod([]int{}), 1)
	testing.expect_value(t, math.sum([]f64{0.5, 0.25, -2}), -1.25)
	testing.expect_value(t, math.prod([]f64{0.5, 0.25, -2}), -0.25)

	dst: [4]int
	out := math.cumsum(dst[:], ints)
	testing.expect_value(t, len(out), 4)
	testing.expect_value(t, dst, [4]int{1, 3, 6, 10})
	short: [2]int
	out = math.cumsum(short[:], ints)
	testing.expect_value(t, len(out), 2)
	testing.expect_value(t, short, [2]int{1, 3})
	out = math.cumsum(dst[:0], ints)
	testing.expect_value(t, len(out), 0)

	inplace := [4]f32{1, 2, 3, 4}
	math.cumsum_inplace(inplace[:])
	testing.expect_value(t, inplace, [4]f32{1, 3, 6, 10})
}

@test
test_power_of_two :: proc(t: ^testing.T) {
	BITS :: 8 * size_of(int)
	for k in 0..<BITS - 1 {
		p := int(1) << uint(k)
		testing.expectf(t, math.is_power_of_two(p), "is_power_of_two(%v) = false", p)
		testing.expectf(t, math.next_power_of_two(p) == p, "next_power_of_two(%v) = %v", p, math.next_power_of_two(p))
		if k > 0 && k < BITS - 2 {
			testing.expectf(t, !math.is_power_of_two(p + 1), "is_power_of_two(%v) = true", p + 1)
			testing.expectf(t, math.next_power_of_two(p + 1) == p << 1, "next_power_of_two(%v) = %v", p + 1, math.next_power_of_two(p + 1))
		}
	}
	testing.expect(t, !math.is_power_of_two(0))
	testing.expect(t, !math.is_power_of_two(-4))
	testing.expect(t, !math.is_power_of_two(min(int)))
	testing.expect(t, !math.is_power_of_two(max(int)))
	testing.expect_value(t, math.next_power_of_two(0), 1)
	testing.expect_value(t, math.next_power_of_two(-5), 1)
	testing.expect_value(t, math.next_power_of_two(min(int)), 1)
	testing.expect_value(t, math.next_power_of_two(1000), 1024)
}

@test
test_to_radians_to_degrees :: proc(t: ^testing.T) {
	testing.expect(t, within_ulps(math.to_radians(f64(180)), f64(math.PI)))
	testing.expect(t, within_ulps(math.to_radians(f64(45)), f64(math.PI / 4)))
	testing.expect(t, within_ulps(math.to_radians(f64(-90)), f64(-math.PI / 2)))
	testing.expect(t, within_ulps(math.to_degrees(f64(math.PI)), f64(180)))
	testing.expect(t, same(math.to_degrees(f64(1)), f64(math.DEG_PER_RAD)))
	testing.expect(t, same(math.to_radians(f64(0)), f64(0)))
	testing.expect(t, same(math.to_degrees(f64(-0.0)), f64(-0.0)))
	testing.expect(t, same(math.to_radians(math.NEG_INF_F64), math.NEG_INF_F64))
	testing.expect(t, within_ulps(math.to_radians(f32(180)), f32(math.PI)))
	testing.expect(t, within_ulps(math.to_degrees(f32(math.PI)), f32(180)))
	testing.expect(t, within_ulps(math.to_radians(f16(180)), f16(math.PI)))
	testing.expect(t, within_ulps(math.to_degrees(f16(math.PI)), f16(180)))
}

@test
test_pow2 :: proc(t: ^testing.T) {
	v64 := f64(1)
	for k in 0..=1024 {
		got := math.pow2_f64(k)
		testing.expectf(t, same(got, v64), "pow2_f64(%v) = %v, want %v", k, got, v64)
		v64 *= 2
	}
	v64 = 1
	for k := 0; k >= -1074; k -= 1 {
		got := math.pow2_f64(k)
		testing.expectf(t, same(got, v64), "pow2_f64(%v) = %v, want %v", k, got, v64)
		v64 *= 0.5
	}
	testing.expect(t, same(math.pow2_f64(-1075), f64(0)))
	testing.expect(t, same(math.pow2_f64(-1076), f64(0)))
	testing.expect(t, same(math.pow2_f64(min(int)), f64(0)))
	testing.expect(t, same(math.pow2_f64(max(int)), math.INF_F64))

	v32 := f32(1)
	for k in 0..=128 {
		got := math.pow2_f32(k)
		testing.expectf(t, same(got, v32), "pow2_f32(%v) = %v, want %v", k, got, v32)
		v32 *= 2
	}
	v32 = 1
	for k := 0; k >= -149; k -= 1 {
		got := math.pow2_f32(k)
		testing.expectf(t, same(got, v32), "pow2_f32(%v) = %v, want %v", k, got, v32)
		v32 *= 0.5
	}
	testing.expect(t, same(math.pow2_f32(-150), f32(0)))
	testing.expect(t, same(math.pow2_f32(-151), f32(0)))
	testing.expect(t, same(math.pow2_f32(-1000), f32(0)))
	testing.expect(t, same(math.pow2_f32(max(int)), math.INF_F32))

	v16 := f16(1)
	for k in 0..=16 {
		got := math.pow2_f16(k)
		testing.expectf(t, same(got, v16), "pow2_f16(%v) = %v, want %v", k, got, v16)
		v16 *= 2
	}
	v16 = 1
	for k := 0; k >= -24; k -= 1 {
		got := math.pow2_f16(k)
		testing.expectf(t, same(got, v16), "pow2_f16(%v) = %v, want %v", k, got, v16)
		v16 *= 0.5
	}
	testing.expect(t, same(math.pow2_f16(-25), f16(0)))
	testing.expect(t, same(math.pow2_f16(-1000), f16(0)))
	testing.expect(t, same(math.pow2_f16(max(int)), math.INF_F16))
}
