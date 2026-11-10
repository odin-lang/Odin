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
