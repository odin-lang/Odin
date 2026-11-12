package test_core_math_linalg_hlsl

import "core:math"
import hlsl "core:math/linalg/hlsl"

import "core:testing"

@test
test_frac :: proc(t: ^testing.T) {
	Datum :: struct {
		x, want: hlsl.double,
	}
	@(static, rodata)
	data := [?]Datum{
		{-1.25, 0.75},
		{-0.75, 0.25},
		{-2,    0},
		{-0.5,  0.5},
		{1.25,  0.25},
		{0.5,   0.5},
		{3,     0},
		{-511.75, 0.25},
	}
	for d in data {
		r := hlsl.frac(d.x)
		testing.expectf(t, r == d.want, "frac(%v) = %v, want %v", d.x, r, d.want)
		f := hlsl.frac(hlsl.float(d.x))
		testing.expectf(t, f == hlsl.float(d.want), "frac(float(%v)) = %v, want %v", d.x, f, d.want)
		h := hlsl.frac(hlsl.half(d.x))
		testing.expectf(t, h == hlsl.half(d.want), "frac(half(%v)) = %v, want %v", d.x, h, d.want)
	}

	x := hlsl.double4{-1.25, -0.75, 1.25, -0.5}
	e := hlsl.double4{0.75, 0.25, 0.25, 0.5}
	testing.expect_value(t, hlsl.frac(x.xy), e.xy)
	testing.expect_value(t, hlsl.frac(x.xyz), e.xyz)
	testing.expect_value(t, hlsl.frac(x), e)
	testing.expect_value(t, hlsl.frac(hlsl.float4(x)), hlsl.float4(e))
	testing.expect_value(t, hlsl.frac(hlsl.half4(x)), hlsl.half4(e))
	testing.expect_value(t, hlsl.frac(hlsl.half2(x.zw)), hlsl.half2(e.zw))
	testing.expect_value(t, hlsl.frac(hlsl.float3(x.yzw)), hlsl.float3(e.yzw))
}

@test
test_frac_below_one :: proc(t: ^testing.T) {
	d := hlsl.frac(hlsl.double(-1e-300))
	testing.expect_value(t, d, hlsl.double(1 - 0.5*math.F64_EPSILON))
	f := hlsl.frac(hlsl.float(-1e-20))
	testing.expect_value(t, f, hlsl.float(1 - 0.5*math.F32_EPSILON))
	h := hlsl.frac(hlsl.half(-1e-4))
	testing.expect_value(t, h, hlsl.half(1 - 0.5*math.F16_EPSILON))

	testing.expect(t, d < 1 && f < 1 && h < 1)
	testing.expect_value(t, hlsl.frac(hlsl.float3{-1e-20, -0.25, 0}), hlsl.float3{1 - 0.5*math.F32_EPSILON, 0.75, 0})

	testing.expect(t, math.is_nan(hlsl.frac(math.nan_f64())))
	testing.expect(t, math.is_nan(hlsl.frac(math.nan_f32())))
	testing.expect(t, math.is_nan(hlsl.frac(math.inf_f64(1))))
	testing.expect(t, math.is_nan(hlsl.frac(math.inf_f32(-1))))
}

@test
test_round_half_to_even :: proc(t: ^testing.T) {
	Datum :: struct {
		x, want: hlsl.double,
	}
	@(static, rodata)
	data := [?]Datum{
		{0.5,     0},
		{1.5,     2},
		{2.5,     2},
		{3.5,     4},
		{-0.5,    0},
		{-1.5,   -2},
		{-2.5,   -2},
		{2.25,    2},
		{2.75,    3},
		{-2.75,  -3},
		{1022.5,  1022},
		{1023.5,  1024},
	}
	for d in data {
		r := hlsl.round(d.x)
		testing.expectf(t, r == d.want, "round(%v) = %v, want %v", d.x, r, d.want)
		f := hlsl.round(hlsl.float(d.x))
		testing.expectf(t, f == hlsl.float(d.want), "round(float(%v)) = %v, want %v", d.x, f, d.want)
		h := hlsl.round(hlsl.half(d.x))
		testing.expectf(t, h == hlsl.half(d.want), "round(half(%v)) = %v, want %v", d.x, h, d.want)
	}

	testing.expect(t, math.sign_bit(hlsl.round(hlsl.double(-0.5))), "round(-0.5) must be -0")
	testing.expect_value(t, hlsl.round(hlsl.double(0.49999999999999994)), 0)
	testing.expect_value(t, hlsl.round(hlsl.double(4503599627370495.5)), 4503599627370496)
	testing.expect_value(t, hlsl.round(hlsl.float(8388607.5)), 8388608)

	x := hlsl.double4{0.5, 1.5, 2.5, -2.5}
	e := hlsl.double4{0, 2, 2, -2}
	testing.expect_value(t, hlsl.round(x.xy), e.xy)
	testing.expect_value(t, hlsl.round(x.xyz), e.xyz)
	testing.expect_value(t, hlsl.round(x), e)
	testing.expect_value(t, hlsl.round(hlsl.float4(x)), hlsl.float4(e))
	testing.expect_value(t, hlsl.round(hlsl.half4(x)), hlsl.half4(e))
}

@test
test_bitcasts :: proc(t: ^testing.T) {
	testing.expect_value(t, hlsl.asint(hlsl.float(1)),   hlsl.int(0x3F80_0000))
	testing.expect_value(t, hlsl.asint(hlsl.float(-2)),  hlsl.int(-0x4000_0000))
	testing.expect_value(t, hlsl.asuint(hlsl.float(-1)), hlsl.uint(0xBF80_0000))
	testing.expect_value(t, hlsl.asuint(hlsl.int(-1)),   hlsl.uint(0xFFFF_FFFF))
	testing.expect_value(t, hlsl.asint(hlsl.uint(0xFFFF_FFFF)), hlsl.int(-1))
	testing.expect_value(t, hlsl.asfloat(hlsl.int(0x3F80_0000)),  hlsl.float(1))
	testing.expect_value(t, hlsl.asfloat(hlsl.uint(0x4049_0FDB)), hlsl.float(math.PI))
	testing.expect(t, math.is_inf(hlsl.asfloat(hlsl.uint(0x7F80_0000)), 1))
	testing.expect(t, math.is_nan(hlsl.asfloat(hlsl.uint(0x7FC0_0000))))

	testing.expect_value(t, hlsl.asint(hlsl.float4{1, -2, 0.5, 0}), hlsl.int4{0x3F80_0000, -0x4000_0000, 0x3F00_0000, 0})
	testing.expect_value(t, hlsl.asuint(hlsl.float3{1, -2, 0.5}), hlsl.uint3{0x3F80_0000, 0xC000_0000, 0x3F00_0000})
	testing.expect_value(t, hlsl.asfloat(hlsl.int2{0x3F80_0000, -0x4000_0000}), hlsl.float2{1, -2})
	testing.expect_value(t, hlsl.asfloat(hlsl.uint4{0x3F80_0000, 0xC000_0000, 0x3F00_0000, 0}), hlsl.float4{1, -2, 0.5, 0})

	m := hlsl.float2x2{1, -2, 0.5, 0}
	testing.expect_value(t, hlsl.asint(m), hlsl.int2x2{0x3F80_0000, -0x4000_0000, 0x3F00_0000, 0})
}

@test
test_radians_degrees_half_range :: proc(t: ^testing.T) {
	d := hlsl.degrees(hlsl.half(200))
	testing.expectf(t, !hlsl.isinf(d) && abs(d - hlsl.half(11459.155902616465)) <= 8, "degrees(half(200)) = %v, want %v", d, hlsl.half(11459.155902616465))
	r := hlsl.radians(hlsl.half(12000))
	testing.expectf(t, !hlsl.isinf(r) && abs(r - hlsl.half(209.43951023931953)) <= 0.125, "radians(half(12000)) = %v, want %v", r, hlsl.half(209.43951023931953))

	d3 := hlsl.degrees(hlsl.half3{1, 200, -200})
	testing.expectf(t, hlsl.all(hlsl.isfinite(d3)), "degrees(half3{1, 200, -200}) = %v", d3)
	r4 := hlsl.radians(hlsl.half4{90, 12000, -12000, 180})
	testing.expectf(t, hlsl.all(hlsl.isfinite(r4)), "radians(half4{90, 12000, -12000, 180}) = %v", r4)

	testing.expect_value(t, hlsl.radians(hlsl.double(180)), math.PI)
	testing.expect_value(t, hlsl.radians(hlsl.double(45)),  math.PI / 4)
	testing.expect_value(t, hlsl.degrees(hlsl.double(math.PI)), 180)
	testing.expect_value(t, hlsl.radians(hlsl.float(180)), hlsl.float(math.PI))
	testing.expect_value(t, hlsl.degrees(hlsl.float(math.PI)), 180)
}

@test
test_refract_grazing :: proc(t: ^testing.T) {
	testing.expect_value(t, hlsl.refract(hlsl.double2{1, 0}, hlsl.double2{0, 1}, 1), hlsl.double2{1, 0})
	testing.expect_value(t, hlsl.refract(hlsl.double3{0, 0, 1}, hlsl.double3{0, 1, 0}, 1), hlsl.double3{0, 0, 1})
	testing.expect_value(t, hlsl.refract(hlsl.double4{0, 0, 0, 1}, hlsl.double4{0, 1, 0, 0}, 1), hlsl.double4{0, 0, 0, 1})
	testing.expect_value(t, hlsl.refract(hlsl.float3{1, 0, 0}, hlsl.float3{0, 1, 0}, 1), hlsl.float3{1, 0, 0})
	testing.expect_value(t, hlsl.refract(hlsl.half2{1, 0}, hlsl.half2{0, 1}, 1), hlsl.half2{1, 0})
}

@test
test_asdouble_asuint_double :: proc(t: ^testing.T) {
	lo, hi := hlsl.asuint(hlsl.double(1))
	testing.expect_value(t, lo, 0)
	testing.expect_value(t, hi, 0x3FF0_0000)
	testing.expect_value(t, hlsl.asdouble(hlsl.uint(0), hlsl.uint(0x3FF0_0000)), 1)
	testing.expect_value(t, hlsl.asdouble(hlsl.uint(0x5444_2D18), hlsl.uint(0x4009_21FB)), math.PI)

	lo2, hi2 := hlsl.asuint(hlsl.double2{1, -2})
	testing.expect_value(t, lo2, hlsl.uint2{0, 0})
	testing.expect_value(t, hi2, hlsl.uint2{0x3FF0_0000, 0xC000_0000})
	testing.expect_value(t, hlsl.asdouble(lo2, hi2), hlsl.double2{1, -2})
}

@test
test_matrix_bitcast_round_trip :: proc(t: ^testing.T) {
	m := hlsl.float2x2{1, -2, 0.5, 0}
	testing.expect_value(t, hlsl.asfloat(hlsl.asint(m)), m)
	testing.expect_value(t, hlsl.asfloat(hlsl.int2x2{0x3F80_0000, -0x4000_0000, 0x3F00_0000, 0}), m)
}

@test
test_sign_returns_int :: proc(t: ^testing.T) {
	#assert(type_of(hlsl.sign(hlsl.half(1))) == hlsl.int)
	#assert(type_of(hlsl.sign(hlsl.float(1))) == hlsl.int)
	#assert(type_of(hlsl.sign(hlsl.double(1))) == hlsl.int)
	#assert(type_of(hlsl.sign(hlsl.half2{})) == hlsl.int2)
	#assert(type_of(hlsl.sign(hlsl.float3{})) == hlsl.int3)
	#assert(type_of(hlsl.sign(hlsl.double4{})) == hlsl.int4)
	#assert(type_of(hlsl.sign(hlsl.uint(1))) == hlsl.int)
	#assert(type_of(hlsl.sign(hlsl.uint3{})) == hlsl.int3)

	Datum :: struct {
		x:    hlsl.double,
		want: hlsl.int,
	}
	@(static, rodata)
	data := [?]Datum{
		{-2.5, -1},
		{-0.0,  0},
		{ 0.0,  0},
		{ 3,    1},
	}
	for d in data {
		testing.expectf(t, hlsl.sign(d.x) == d.want, "sign(%v) = %v, want %v", d.x, hlsl.sign(d.x), d.want)
		testing.expectf(t, hlsl.sign(hlsl.float(d.x)) == d.want, "sign(float(%v)) = %v, want %v", d.x, hlsl.sign(hlsl.float(d.x)), d.want)
		testing.expectf(t, hlsl.sign(hlsl.half(d.x)) == d.want, "sign(half(%v)) = %v, want %v", d.x, hlsl.sign(hlsl.half(d.x)), d.want)
	}

	testing.expect_value(t, hlsl.sign(math.nan_f64()), 0)
	testing.expect_value(t, hlsl.sign(math.nan_f32()), 0)
	testing.expect_value(t, hlsl.sign(math.nan_f16()), 0)
	testing.expect_value(t, hlsl.sign(math.inf_f64(-1)), -1)
	testing.expect_value(t, hlsl.sign(hlsl.double(-1e-300)), -1)

	testing.expect_value(t, hlsl.sign(hlsl.float3{-2, 0, 5}), hlsl.int3{-1, 0, 1})
	testing.expect_value(t, hlsl.sign(hlsl.half4{-2, 0, 5, -0.5}), hlsl.int4{-1, 0, 1, -1})
	testing.expect_value(t, hlsl.sign(hlsl.double2{math.nan_f64(), -1}), hlsl.int2{0, -1})
	testing.expect_value(t, hlsl.sign(hlsl.uint3{0, 1, 7}), hlsl.int3{0, 1, 1})
}
