#+build i386, amd64
package test_internal

import "base:intrinsics"
import "core:sys/info"
import "core:testing"

// A bare #simd value wider than 16 bytes must take the same registers whatever target features either side enables.
// The Odin conventions pass it by pointer and return it in 16-byte pieces in XMM0 to XMM3 (the hidden pointer past 64 bytes).
// Each value is checked lane by lane, across calls between procedures with and without AVX and AVX-512.

@(private="file")
wide_seed := 2

@(private="file")
Packed_Wide :: struct #packed {
	pad: u8,
	v:   #simd[8]f32,
}

@(private="file")
wide_make :: #force_inline proc "contextless" ($V: typeid, x: int) -> V where intrinsics.type_is_simd_vector(V) {
	E :: intrinsics.type_elem_type(V)
	N :: size_of(V)/size_of(E)
	arr: [N]E
	for &e, i in arr {
		e = E(x + 3*i + 1)
	}
	return transmute(V)arr
}

// Weighted by lane, ergo lanes out of place change the sum
@(private="file")
wide_sum :: #force_inline proc "contextless" (v: $V) -> (s: f64) where intrinsics.type_is_simd_vector(V) {
	E :: intrinsics.type_elem_type(V)
	N :: size_of(V)/size_of(E)
	for e, i in transmute([N]E)v {
		s += f64(e) * f64(i + 1)
	}
	return
}

@(private="file") plain_ret   :: #force_no_inline proc($V: typeid, x: int) -> V         { return wide_make(V, x) }
@(private="file") plain_args  :: #force_no_inline proc(a, b: $V) -> f64                 { return wide_sum(a) + 1000*wide_sum(b) }
@(private="file") plain_tuple :: #force_no_inline proc($V: typeid, x: int) -> (bool, V) { return x > 0, wide_make(V, x) }

@(private="file", enable_target_feature="avx") avx_ret   :: #force_no_inline proc($V: typeid, x: int) -> V         { return wide_make(V, x) }
@(private="file", enable_target_feature="avx") avx_args  :: #force_no_inline proc(a, b: $V) -> f64                 { return wide_sum(a) + 1000*wide_sum(b) }
@(private="file", enable_target_feature="avx") avx_tuple :: #force_no_inline proc($V: typeid, x: int) -> (bool, V) { return x > 0, wide_make(V, x) }

@(private="file", enable_target_feature="avx512f") avx512_ret   :: #force_no_inline proc($V: typeid, x: int) -> V         { return wide_make(V, x) }
@(private="file", enable_target_feature="avx512f") avx512_args  :: #force_no_inline proc(a, b: $V) -> f64                 { return wide_sum(a) + 1000*wide_sum(b) }
@(private="file", enable_target_feature="avx512f") avx512_tuple :: #force_no_inline proc($V: typeid, x: int) -> (bool, V) { return x > 0, wide_make(V, x) }

// The results are used after each call, ergo none is a tail call
@(private="file", enable_target_feature="avx")
avx_calls_plain :: #force_no_inline proc($V: typeid, x: int) -> f64 {
	v := plain_ret(V, x)
	ok, w := plain_tuple(V, x+7)
	return wide_sum(v) + 3*wide_sum(w) + f64(int(ok)) + plain_args(v, w)
}

@(private="file", enable_target_feature="avx512f")
avx512_calls_avx :: #force_no_inline proc($V: typeid, x: int) -> f64 {
	v := avx_ret(V, x)
	ok, w := avx_tuple(V, x+7)
	return wide_sum(v) + 3*wide_sum(w) + f64(int(ok)) + avx_args(v, w)
}

@(private="file")
expect_lanes :: proc(t: ^testing.T, name: string, got, want: $V, loc := #caller_location) {
	same := transmute([size_of(V)]u8)got == transmute([size_of(V)]u8)want
	testing.expectf(t, same, "%s %v: got %v, want %v", name, typeid_of(V), got, want, loc=loc)
}

@(private="file")
check_wide :: proc(t: ^testing.T, $V: typeid, features: info.CPU_Features) {
	x := intrinsics.volatile_load(&wide_seed)
	a := wide_make(V, x)
	b := wide_make(V, x+7)
	want_args  := wide_sum(a) + 1000*wide_sum(b)
	want_calls := wide_sum(a) + 3*wide_sum(b) + 1 + want_args

	ok, v := plain_tuple(V, x)
	expect_lanes(t, "plain_ret", plain_ret(V, x), a)
	expect_lanes(t, "plain_tuple", v, a)
	testing.expect(t, ok)
	testing.expect_value(t, plain_args(a, b), want_args)

	if .avx in features {
		ok, v = avx_tuple(V, x)
		expect_lanes(t, "avx_ret", avx_ret(V, x), a)
		expect_lanes(t, "avx_tuple", v, a)
		testing.expect(t, ok)
		testing.expect_value(t, avx_args(a, b), want_args)
		testing.expect_value(t, avx_calls_plain(V, x), want_calls)
	}
	if .avx512f in features {
		ok, v = avx512_tuple(V, x)
		expect_lanes(t, "avx512_ret", avx512_ret(V, x), a)
		expect_lanes(t, "avx512_tuple", v, a)
		testing.expect(t, ok)
		testing.expect_value(t, avx512_args(a, b), want_args)
		testing.expect_value(t, avx512_calls_avx(V, x), want_calls)
	}
}

@(test)
test_wide_simd_abi :: proc(t: ^testing.T) {
	features := info.cpu_features()

	check_wide(t, #simd[4]f32,  features) // 16 bytes, in one register already
	check_wide(t, #simd[8]f32,  features)
	check_wide(t, #simd[4]f64,  features)
	check_wide(t, #simd[16]f32, features)
	check_wide(t, #simd[8]i32,  features)
	check_wide(t, #simd[32]u8,  features)
	check_wide(t, #simd[16]f16, features)
	check_wide(t, #simd[32]f32, features) // 128 bytes, through the hidden pointer

	// A pointer to an under-aligned vector is not passed as it is
	p := Packed_Wide{v = wide_make(#simd[8]f32, 5)}
	q := wide_make(#simd[8]f32, 6)
	testing.expect_value(t, plain_args(p.v, q), wide_sum(p.v) + 1000*wide_sum(q))
	if .avx in features {
		testing.expect_value(t, avx_args(p.v, q), wide_sum(p.v) + 1000*wide_sum(q))
	}
}
