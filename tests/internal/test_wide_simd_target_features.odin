#+build i386, amd64
package test_internal

import "base:intrinsics"
import "core:sys/info"
import "core:testing"

// A vector wider than the build's vector registers is passed and returned as it would be with only the build's target features.
// A procedure that enables AVX or AVX-512 of its own must still agree with its callers, which have neither.
// Each value is checked lane by lane, across calls in both directions.

@(private="file")
tf_seed := 2

@(private="file")
tf_make :: #force_inline proc "contextless" ($V: typeid, x: int) -> V where intrinsics.type_is_simd_vector(V) {
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
tf_sum :: #force_inline proc "contextless" (v: $V) -> (s: f64) where intrinsics.type_is_simd_vector(V) {
	E :: intrinsics.type_elem_type(V)
	N :: size_of(V)/size_of(E)
	for e, i in transmute([N]E)v {
		s += f64(e) * f64(i + 1)
	}
	return
}

@(private="file") c_plain_ret  :: #force_no_inline proc "c" ($V: typeid, x: int) -> V { return tf_make(V, x) }
@(private="file") c_plain_args :: #force_no_inline proc "c" (a, b: $V) -> f64        { return tf_sum(a) + 1000*tf_sum(b) }
@(private="file") odin_plain_tuple :: #force_no_inline proc($V: typeid, x: int) -> (bool, V) { return x > 0, tf_make(V, x) }

@(private="file", enable_target_feature="avx") c_avx_ret  :: #force_no_inline proc "c" ($V: typeid, x: int) -> V { return tf_make(V, x) }
@(private="file", enable_target_feature="avx") c_avx_args :: #force_no_inline proc "c" (a, b: $V) -> f64        { return tf_sum(a) + 1000*tf_sum(b) }
@(private="file", enable_target_feature="avx") odin_avx_tuple :: #force_no_inline proc($V: typeid, x: int) -> (bool, V) { return x > 0, tf_make(V, x) }

@(private="file", enable_target_feature="avx512f") c_avx512_ret  :: #force_no_inline proc "c" ($V: typeid, x: int) -> V { return tf_make(V, x) }
@(private="file", enable_target_feature="avx512f") c_avx512_args :: #force_no_inline proc "c" (a, b: $V) -> f64        { return tf_sum(a) + 1000*tf_sum(b) }
@(private="file", enable_target_feature="avx512f") odin_avx512_tuple :: #force_no_inline proc($V: typeid, x: int) -> (bool, V) { return x > 0, tf_make(V, x) }

// The results are used after each call, ergo none is a tail call
@(private="file", enable_target_feature="avx")
c_avx_calls_plain :: #force_no_inline proc "c" ($V: typeid, x: int) -> f64 {
	v := c_plain_ret(V, x)
	w := c_plain_ret(V, x+7)
	return tf_sum(v) + 3*tf_sum(w) + c_plain_args(v, w)
}

@(private="file", enable_target_feature="avx512f")
c_avx512_calls_avx :: #force_no_inline proc "c" ($V: typeid, x: int) -> f64 {
	v := c_avx_ret(V, x)
	w := c_avx_ret(V, x+7)
	return tf_sum(v) + 3*tf_sum(w) + c_avx_args(v, w)
}

@(private="file")
tf_expect_lanes :: proc(t: ^testing.T, name: string, got, want: $V, loc := #caller_location) {
	same := transmute([size_of(V)]u8)got == transmute([size_of(V)]u8)want
	testing.expectf(t, same, "%s %v: got %v, want %v", name, typeid_of(V), got, want, loc=loc)
}

@(private="file")
tf_check :: proc(t: ^testing.T, $V: typeid, features: info.CPU_Features) {
	x := intrinsics.volatile_load(&tf_seed)
	a := tf_make(V, x)
	b := tf_make(V, x+7)
	want_args  := tf_sum(a) + 1000*tf_sum(b)
	want_calls := tf_sum(a) + 3*tf_sum(b) + want_args

	ok, v := odin_plain_tuple(V, x)
	tf_expect_lanes(t, "c_plain_ret", c_plain_ret(V, x), a)
	tf_expect_lanes(t, "odin_plain_tuple", v, a)
	testing.expect(t, ok)
	testing.expect_value(t, c_plain_args(a, b), want_args)

	if .avx in features {
		ok, v = odin_avx_tuple(V, x)
		tf_expect_lanes(t, "c_avx_ret", c_avx_ret(V, x), a)
		tf_expect_lanes(t, "odin_avx_tuple", v, a)
		testing.expect(t, ok)
		testing.expect_value(t, c_avx_args(a, b), want_args)
		testing.expect_value(t, c_avx_calls_plain(V, x), want_calls)
	}
	if .avx512f in features {
		ok, v = odin_avx512_tuple(V, x)
		tf_expect_lanes(t, "c_avx512_ret", c_avx512_ret(V, x), a)
		tf_expect_lanes(t, "odin_avx512_tuple", v, a)
		testing.expect(t, ok)
		testing.expect_value(t, c_avx512_args(a, b), want_args)
		testing.expect_value(t, c_avx512_calls_avx(V, x), want_calls)
	}
}

@(test)
test_wide_simd_target_features :: proc(t: ^testing.T) {
	features := info.cpu_features()

	tf_check(t, #simd[4]f32,  features) // 16 bytes, in one register already
	tf_check(t, #simd[8]f32,  features)
	tf_check(t, #simd[4]f64,  features)
	tf_check(t, #simd[16]f32, features)
	tf_check(t, #simd[8]i32,  features)
	tf_check(t, #simd[32]u8,  features)
	tf_check(t, #simd[16]f16, features)
	tf_check(t, #simd[32]f32, features) // 128 bytes
}
