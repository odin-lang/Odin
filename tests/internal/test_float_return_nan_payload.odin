package test_internal

import "core:testing"

@(test)
float_return_keeps_nan_payload :: proc(t: ^testing.T) {
	ret16 :: #force_no_inline proc(x: f16) -> f16 { return x }
	ret32 :: #force_no_inline proc(x: f32) -> f32 { return x }
	ret64 :: #force_no_inline proc(x: f64) -> f64 { return x }
	ret32_contextless :: #force_no_inline proc "contextless" (x: f32) -> f32 { return x }
	ret64_contextless :: #force_no_inline proc "contextless" (x: f64) -> f64 { return x }
	pair32 :: #force_no_inline proc(x: f32) -> (int, f32) { return 1, x }
	pair64 :: #force_no_inline proc(x: f64) -> (int, f64) { return 1, x }

	halves := [?]u16{0x7d01, 0xfdff, 0x7c01, 0x7e01, 0x0001}
	for h in halves {
		got := transmute(u16)ret16(transmute(f16)h)
		testing.expectf(t, got == h, "f16 %4x -> %4x", h, got)
	}
	singles := [?]u32{0x7fa0_0001, 0xffbf_ffff, 0x7f80_0001, 0x7fc1_2345, 0x0000_0001}
	for s in singles {
		x := transmute(f32)s
		_, p := pair32(x)
		testing.expectf(t, transmute(u32)ret32(x) == s, "odin f32 %8x -> %8x", s, transmute(u32)ret32(x))
		testing.expectf(t, transmute(u32)ret32_contextless(x) == s, "contextless f32 %8x -> %8x", s, transmute(u32)ret32_contextless(x))
		testing.expectf(t, transmute(u32)p == s, "multiple return f32 %8x -> %8x", s, transmute(u32)p)
	}
	doubles := [?]u64{0x7ff4_0000_0000_0001, 0xfff7_ffff_ffff_ffff, 0x7ff0_0000_0000_0001, 0x7ff8_1234_5678_9abc, 0x0000_0000_0000_0001}
	for d in doubles {
		x := transmute(f64)d
		_, p := pair64(x)
		testing.expectf(t, transmute(u64)ret64(x) == d, "odin f64 %16x -> %16x", d, transmute(u64)ret64(x))
		testing.expectf(t, transmute(u64)ret64_contextless(x) == d, "contextless f64 %16x -> %16x", d, transmute(u64)ret64_contextless(x))
		testing.expectf(t, transmute(u64)p == d, "multiple return f64 %16x -> %16x", d, transmute(u64)p)
	}
}
