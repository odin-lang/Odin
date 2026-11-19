package test_core_math_linalg_hlsl

import hlsl "core:math/linalg/hlsl"

import "core:testing"

@test
test_lerp :: proc(t: ^testing.T) {
	x := hlsl.double4{0, 0, 0, 0}
	y := hlsl.double4{10, 20, 30, 40}
	w := hlsl.double4{0.5, 0.25, 0.75, 1}
	e := hlsl.double4{5, 5, 22.5, 40}

	r2 := hlsl.lerp(x.xy, y.xy, w.xy)
	testing.expectf(t, r2 == e.xy, "lerp(%v, %v, %v) = %v, want %v", x.xy, y.xy, w.xy, r2, e.xy)
	r3 := hlsl.lerp(x.xyz, y.xyz, w.xyz)
	testing.expectf(t, r3 == e.xyz, "lerp(%v, %v, %v) = %v, want %v", x.xyz, y.xyz, w.xyz, r3, e.xyz)
	r4 := hlsl.lerp(x, y, w)
	testing.expectf(t, r4 == e, "lerp(%v, %v, %v) = %v, want %v", x, y, w, r4, e)

	f4 := hlsl.lerp(hlsl.float4(x), hlsl.float4(y), hlsl.float4(w))
	testing.expectf(t, f4 == hlsl.float4(e), "lerp float4 = %v, want %v", f4, e)
	h4 := hlsl.lerp(hlsl.half4(x), hlsl.half4(y), hlsl.half4(w))
	testing.expectf(t, h4 == hlsl.half4(e), "lerp half4 = %v, want %v", h4, e)
}

@test
test_normalize_scalar :: proc(t: ^testing.T) {
	for v in ([]hlsl.double{-1000, -10, -0.5, 0.5, 3, 1000}) {
		e := hlsl.double(1) if v > 0 else -1
		d := hlsl.normalize(v)
		testing.expectf(t, d == e, "normalize(%v) = %v, want %v", v, d, e)
		f := hlsl.normalize(hlsl.float(v))
		testing.expectf(t, f == hlsl.float(e), "normalize(float(%v)) = %v, want %v", v, f, e)
		h := hlsl.normalize(hlsl.half(v))
		testing.expectf(t, h == hlsl.half(e), "normalize(half(%v)) = %v, want %v", v, h, e)
	}
}

@test
test_isinf_isfinite :: proc(t: ^testing.T) {
	Datum :: struct {
		v:      hlsl.double,
		inf:    bool,
		finite: bool,
	}
	@(static, rodata)
	data := [?]Datum{
		{0h0000_0000_0000_0000, false, true},
		{0h8000_0000_0000_0000, false, true},
		{1,                     false, true},
		{-1,                    false, true},
		{0h7ff0_0000_0000_0000, true,  false},
		{0hfff0_0000_0000_0000, true,  false},
		{0h7ff8_0000_0000_0000, false, false},
		{0hfff8_0000_0000_0000, false, false},
	}

	for d in data {
		testing.expectf(t, hlsl.isinf(d.v) == d.inf, "isinf(%v) = %v, want %v", d.v, hlsl.isinf(d.v), d.inf)
		testing.expectf(t, hlsl.isfinite(d.v) == d.finite, "isfinite(%v) = %v, want %v", d.v, hlsl.isfinite(d.v), d.finite)

		f := hlsl.float(d.v)
		testing.expectf(t, hlsl.isinf(f) == d.inf, "isinf(float(%v)) = %v, want %v", d.v, hlsl.isinf(f), d.inf)
		testing.expectf(t, hlsl.isfinite(f) == d.finite, "isfinite(float(%v)) = %v, want %v", d.v, hlsl.isfinite(f), d.finite)

		h := hlsl.half(d.v)
		testing.expectf(t, hlsl.isinf(h) == d.inf, "isinf(half(%v)) = %v, want %v", d.v, hlsl.isinf(h), d.inf)
		testing.expectf(t, hlsl.isfinite(h) == d.finite, "isfinite(half(%v)) = %v, want %v", d.v, hlsl.isfinite(h), d.finite)
	}

	finite_d := [?]hlsl.double{0h0000_0000_0000_0001, 0h8000_0000_0000_0001, 0h7fef_ffff_ffff_ffff}
	for v in finite_d {
		testing.expectf(t, !hlsl.isinf(v), "isinf(%h) = true, want false", v)
		testing.expectf(t, hlsl.isfinite(v), "isfinite(%h) = false, want true", v)
	}
	finite_f := [?]hlsl.float{0h0000_0001, 0h8000_0001, 0h7f7f_ffff}
	for v in finite_f {
		testing.expectf(t, !hlsl.isinf(v), "isinf(%h) = true, want false", v)
		testing.expectf(t, hlsl.isfinite(v), "isfinite(%h) = false, want true", v)
	}
	finite_h := [?]hlsl.half{0h0001, 0h8001, 0h7bff}
	for v in finite_h {
		testing.expectf(t, !hlsl.isinf(v), "isinf(%h) = true, want false", v)
		testing.expectf(t, hlsl.isfinite(v), "isfinite(%h) = false, want true", v)
	}

	v4 := hlsl.float4{0, 0h7f80_0000, 0h7fc0_0000, 1}
	testing.expect_value(t, hlsl.isinf(v4), hlsl.bool4{false, true, false, false})
	testing.expect_value(t, hlsl.isfinite(v4), hlsl.bool4{true, false, false, true})
}

@test
test_refract :: proc(t: ^testing.T) {
	i := hlsl.normalize(hlsl.double4{1, -1, 0.5, 0.25})
	n := hlsl.double4{0, 1, 0, 0}
	ni := hlsl.dot(n, i)

	for eta in ([]hlsl.double{0.5, 0.75, 1, 1.25, 1.5, 2}) {
		k := 1 - eta*eta*(1 - ni*ni)
		e: hlsl.double4
		if k >= 0 {
			e = eta*i - (eta*ni + hlsl.sqrt(k))*n
		}

		d4 := hlsl.refract(i, n, eta)
		testing.expectf(t, hlsl.length(d4 - e) < 1e-12, "refract(%v, %v, %v) = %v, want %v", i, n, eta, d4, e)
		d3 := hlsl.refract(i.xyz, n.xyz, eta)
		testing.expectf(t, hlsl.length(d3 - e.xyz) < 1e-12, "refract(%v, %v, %v) = %v, want %v", i.xyz, n.xyz, eta, d3, e.xyz)
		d2 := hlsl.refract(i.xy, n.xy, eta)
		testing.expectf(t, hlsl.length(d2 - e.xy) < 1e-12, "refract(%v, %v, %v) = %v, want %v", i.xy, n.xy, eta, d2, e.xy)

		f4 := hlsl.refract(hlsl.float4(i), hlsl.float4(n), hlsl.float(eta))
		testing.expectf(t, hlsl.length(f4 - hlsl.float4(e)) < 1e-6, "refract(%v, %v, %v) = %v, want %v", i, n, eta, f4, e)
		f3 := hlsl.refract(hlsl.float3(i.xyz), hlsl.float3(n.xyz), hlsl.float(eta))
		testing.expectf(t, hlsl.length(f3 - hlsl.float3(e.xyz)) < 1e-6, "refract(%v, %v, %v) = %v, want %v", i.xyz, n.xyz, eta, f3, e.xyz)
		f2 := hlsl.refract(hlsl.float2(i.xy), hlsl.float2(n.xy), hlsl.float(eta))
		testing.expectf(t, hlsl.length(f2 - hlsl.float2(e.xy)) < 1e-6, "refract(%v, %v, %v) = %v, want %v", i.xy, n.xy, eta, f2, e.xy)

		h3 := hlsl.refract(hlsl.half3(i.xyz), hlsl.half3(n.xyz), hlsl.half(eta))
		testing.expectf(t, hlsl.length(h3 - hlsl.half3(e.xyz)) < 0.01, "refract(%v, %v, %v) = %v, want %v", i.xyz, n.xyz, eta, h3, e.xyz)
	}
}
