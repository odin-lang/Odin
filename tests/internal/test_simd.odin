package test_internal

import "base:intrinsics"
import "core:math"
import "core:simd"
import "core:testing"

// `simd_interleave` derives its lane count as operand width times argument count, so it is a
// power of two only when the argument count is. The rejection of the rest cannot be asserted
// from a test -- it is a compile error -- so what is pinned here is the other side: the widths
// that must keep working, and the values they carry.

// More than two operands lower to a riffle of two-way shuffles rather than one intrinsic, so
// the lane ORDER is asserted and not just the width.

@(test)
simd_interleave_power_of_two_widths :: proc(t: ^testing.T) {
	a: #simd[4]i32 = {1, 2, 3, 4}
	b: #simd[4]i32 = {5, 6, 7, 8}
	c: #simd[4]i32 = {9, 10, 11, 12}
	d: #simd[4]i32 = {13, 14, 15, 16}

	two := intrinsics.simd_interleave(a, b)
	testing.expect_value(t, len(two), 8)
	testing.expect_value(t, simd_extract_i32(two, 0), 1)
	testing.expect_value(t, simd_extract_i32(two, 1), 5)
	testing.expect_value(t, simd_extract_i32(two, 2), 2)
	testing.expect_value(t, simd_extract_i32(two, 3), 6)

	four := intrinsics.simd_interleave(a, b, c, d)
	testing.expect_value(t, len(four), 16)
	testing.expect_value(t, simd_extract_i32(four, 0), 1)
	testing.expect_value(t, simd_extract_i32(four, 1), 5)
	testing.expect_value(t, simd_extract_i32(four, 2), 9)
	testing.expect_value(t, simd_extract_i32(four, 3), 13)
	testing.expect_value(t, simd_extract_i32(four, 4), 2)
	testing.expect_value(t, simd_extract_i32(four, 7), 14)
	testing.expect_value(t, simd_extract_i32(four, 15), 16)

	// a single argument is a power of two count as well, and must not be caught by the guard
	one := intrinsics.simd_interleave(a)
	testing.expect_value(t, len(one), 4)

	x, y := intrinsics.simd_deinterleave(two, 2)
	testing.expect_value(t, len(x), 4)
	testing.expect_value(t, len(y), 4)
	testing.expect_value(t, simd_extract_i32(x, 0), 1)
	testing.expect_value(t, simd_extract_i32(y, 0), 5)
}

// `simd_deinterleave` splits by stride, so output `j` is the input taken every N lanes from
// lane `j`. N > 2 lowers to shuffles for the same reason interleave does, only arm64 could
// select the intrinsic. The round trip is asserted, not just the widths.

@(test)
simd_deinterleave_splits_by_stride :: proc(t: ^testing.T) {
	v: #simd[16]i32
	for i in 0..<16 {
		v = intrinsics.simd_replace(v, i, i32(i))
	}

	a2, b2 := intrinsics.simd_deinterleave(v, 2)
	testing.expect_value(t, len(a2), 8)
	testing.expect_value(t, simd_extract_i32(a2, 0), 0)
	testing.expect_value(t, simd_extract_i32(a2, 1), 2)
	testing.expect_value(t, simd_extract_i32(b2, 0), 1)
	testing.expect_value(t, simd_extract_i32(b2, 7), 15)

	a4, b4, c4, d4 := intrinsics.simd_deinterleave(v, 4)
	testing.expect_value(t, len(a4), 4)
	testing.expect_value(t, simd_extract_i32(a4, 0), 0)
	testing.expect_value(t, simd_extract_i32(b4, 0), 1)
	testing.expect_value(t, simd_extract_i32(c4, 0), 2)
	testing.expect_value(t, simd_extract_i32(d4, 0), 3)
	testing.expect_value(t, simd_extract_i32(a4, 3), 12)
	testing.expect_value(t, simd_extract_i32(d4, 3), 15)

	// interleave is the inverse, so the pair must round trip
	r := intrinsics.simd_interleave(a4, b4, c4, d4)
	testing.expect_value(t, len(r), 16)
	testing.expect_value(t, simd_extract_i32(r, 0), 0)
	testing.expect_value(t, simd_extract_i32(r, 7), 7)
	testing.expect_value(t, simd_extract_i32(r, 15), 15)
}

simd_extract_i32 :: #force_inline proc(v: $V/#simd[$N]i32, $I: int) -> i32 {
	return intrinsics.simd_extract(v, I)
}

// `simd_shuffle` and `swizzle` size their result from the index list, which can be twice the
// operand width, so both can construct a `#simd` wider than the syntax accepts. What is pinned
// here is the boundary that must keep working: exactly SIMD_ELEMENT_COUNT_MAX lanes, and a
// `swizzle` over a plain array, which is not bound by the `#simd` limit at all.

@(test)
simd_construction_at_the_element_count_max :: proc(t: ^testing.T) {
	a: #simd[32]i32 = 1
	at_max := intrinsics.simd_shuffle(a, a,
		0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15,
		16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
		32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
		48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63)
	testing.expect_value(t, len(at_max), 64)

	b: #simd[8]i32 = {1, 2, 3, 4, 5, 6, 7, 8}
	under := intrinsics.simd_shuffle(b, b, 0, 1, 2, 3, 8, 9, 10, 11)
	testing.expect_value(t, len(under), 8)
	testing.expect_value(t, simd_extract_i32(under, 4), 1)

	sw := swizzle(b, 7, 6, 5, 4, 3, 2, 1, 0)
	testing.expect_value(t, len(sw), 8)
	testing.expect_value(t, simd_extract_i32(sw, 0), 8)

	// a plain array is not a #simd vector, so the element-count limit must not reach it
	arr: [96]i32
	arr[95] = 7
	asw := swizzle(arr, 95, 0, 1)
	testing.expect_value(t, len(asw), 3)
	testing.expect_value(t, asw[0], 7)

	d, e: #simd[32]i32
	ilv := intrinsics.simd_interleave(d, e)
	testing.expect_value(t, len(ilv), 64)
}

// A swizzle may repeat indices to produce a result wider than its operand. `core:crypto`
// depends on it -- chacha20's simd256 path doubles a 4-lane state with eight indices -- so
// there is deliberately no upper bound on the index count.

@(test)
swizzle_may_widen_its_operand :: proc(t: ^testing.T) {
	v: [2]f32 = {1, 2}
	testing.expect_value(t, swizzle(v, 0, 0, 0, 0), [4]f32{1, 1, 1, 1})
	testing.expect_value(t, swizzle(v, 0, 1, 0, 1), [4]f32{1, 2, 1, 2})

	a: [3]i32 = {7, 8, 9}
	testing.expect_value(t, swizzle(a, 2, 2, 2, 2, 2, 2), [6]i32{9, 9, 9, 9, 9, 9})

	// the same shape on a #simd vector: four lanes widened to eight
	q: #simd[4]u32 = {1, 2, 3, 4}
	w := swizzle(q, 0, 1, 2, 3, 0, 1, 2, 3)
	testing.expect_value(t, len(w), 8)
	testing.expect_value(t, intrinsics.simd_extract(w, 4), u32(1))
	testing.expect_value(t, intrinsics.simd_extract(w, 7), u32(4))
}

// simd_select takes lane i from the 1st operand where the mask lane is nonzero/true
// and from the 2nd otherwise
@(test)
simd_select_const_ops :: proc(t: ^testing.T) {
	mask: #simd[4]i32 = {7, 0, -1, 0}
	x:    #simd[4]i32 = {1, 2, 3, 4}
	y:    #simd[4]i32 = {5, 6, 7, 8}
	testing.expect_value(t, simd.to_array(intrinsics.simd_select(mask, x, y)), [4]i32{1, 6, 3, 8})

	bmask: #simd[4]b32 = {false, true, true, false}
	fx:    #simd[4]f32 = {1.5, 2.5, 3.5, 4.5}
	fy:    #simd[4]f32 = {-1, -2, -3, -4}
	testing.expect_value(t, simd.to_array(intrinsics.simd_select(bmask, fx, fy)), [4]f32{-1, 2.5, 3.5, -4})
}

// simd_runtime_swizzle reads src[indices[i]] into lane i
@(test)
simd_runtime_swizzle_const_ops :: proc(t: ^testing.T) {
	bytes:   #simd[16]u8 = {0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150}
	reverse: #simd[16]u8 = {15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0}
	testing.expect_value(t, simd.to_array(intrinsics.simd_runtime_swizzle(bytes, reverse)),
		[16]u8{150, 140, 130, 120, 110, 100, 90, 80, 70, 60, 50, 40, 30, 20, 10, 0})

	words:  #simd[4]u32 = {100, 200, 300, 400}
	rotate: #simd[4]u32 = {1, 2, 3, 0}
	testing.expect_value(t, simd.to_array(intrinsics.simd_runtime_swizzle(words, rotate)), [4]u32{200, 300, 400, 100})

	halves: #simd[8]i16 = {0, 1, 2, 3, 4, 5, 6, 7}
	dup:    #simd[8]i16 = {0, 0, 3, 3, 5, 5, 7, 7}
	testing.expect_value(t, simd.to_array(intrinsics.simd_runtime_swizzle(halves, dup)), [8]i16{0, 0, 3, 3, 5, 5, 7, 7})
}

// runtime operands must evaluate once
@(test)
simd_select_runtime_ops :: proc(t: ^testing.T) {
	calls: i32 = 0
	mask: #simd[4]i32 = {1, 0, -1, 0}

	count_calls :: proc(c: ^i32, site: i32) -> #simd[4]i32 {
		c^ += 1
		return (#simd[4]i32)(site*100 + c^)
	}

	r := intrinsics.simd_select(mask, count_calls(&calls, 1), count_calls(&calls, 2))
	testing.expect_value(t, simd.to_array(r), [4]i32{101, 202, 101, 202})
}

// runtime operands must evaluate once
@(test)
simd_runtime_swizzle_runtime_ops :: proc(t: ^testing.T) {
	calls: u16 = 0
	src: #simd[8]u16 = {0, 1, 2, 3, 4, 5, 6, 7}

	count_calls :: proc(c: ^u16) -> #simd[8]u16 {
		c^ += 1
		return (#simd[8]u16)(c^)
	}

	r := intrinsics.simd_runtime_swizzle(src, count_calls(&calls))
	testing.expect_value(t, simd.to_array(r), [8]u16{1, 1, 1, 1, 1, 1, 1, 1})
}

// A pairwise operation folds adjacent lanes within each operand, so it needs an even lane
// count -- `base:intrinsics` declares `LANES % 2 == 0`. At one lane it has nothing to pair
// with and silently switches to combining the two operands instead, which is why that width
// is rejected rather than defined.

@(test)
simd_pairwise_folds_adjacent_lanes :: proc(t: ^testing.T) {
	a: #simd[2]i32 = {10, 3}
	b: #simd[2]i32 = {20, 4}

	add := intrinsics.simd_pairwise_add(a, b)
	testing.expect_value(t, intrinsics.simd_extract(add, 0), i32(13))
	testing.expect_value(t, intrinsics.simd_extract(add, 1), i32(24))

	sub := intrinsics.simd_pairwise_sub(a, b)
	testing.expect_value(t, intrinsics.simd_extract(sub, 0), i32(7))
	testing.expect_value(t, intrinsics.simd_extract(sub, 1), i32(16))

	c: #simd[4]f32 = {1, 2, 3, 4}
	d: #simd[4]f32 = {5, 6, 7, 8}
	f := intrinsics.simd_pairwise_add(c, d)
	testing.expect_value(t, intrinsics.simd_extract(f, 0), f32(3))
	testing.expect_value(t, intrinsics.simd_extract(f, 1), f32(7))

	// the other six builtins sharing this arm take a single lane, and must stay unaffected
	o: #simd[1]i32 = 7
	p: #simd[1]i32 = 2
	testing.expect_value(t, intrinsics.simd_extract(intrinsics.simd_add(o, p), 0), i32(9))
	testing.expect_value(t, intrinsics.simd_extract(intrinsics.simd_max(o, p), 0), i32(7))
}

// `#simd[?]T{...}`  The inferred form must agree with the explicit one.

@(test)
simd_inferred_length_from_a_compound_literal :: proc(t: ^testing.T) {
	a := #simd[?]i32{1, 2, 3, 4}
	testing.expect_value(t, len(a), 4)
	testing.expect_value(t, intrinsics.type_is_simd_vector(type_of(a)), true)
	testing.expect_value(t, typeid_of(type_of(a)), typeid_of(#simd[4]i32))
	testing.expect_value(t, intrinsics.simd_extract(a, 0), i32(1))
	testing.expect_value(t, intrinsics.simd_extract(a, 3), i32(4))

	b := #simd[?]f32{1.5, 2.5}
	testing.expect_value(t, len(b), 2)
	testing.expect_value(t, typeid_of(type_of(b)), typeid_of(#simd[2]f32))
	testing.expect_value(t, intrinsics.simd_extract(b, 1), f32(2.5))

	// the inferred vector must work with the intrinsics, which is the point of the tag
	testing.expect_value(t, intrinsics.simd_extract(intrinsics.simd_add(a, a), 3), i32(8))

	// a plain `[?]` array is unaffected
	c := [?]i32{1, 2, 3}
	testing.expect_value(t, len(c), 3)
	testing.expect_value(t, intrinsics.type_is_array(type_of(c)), true)
}

// `core:simd` aliased `pairwise_sub` to `simd_pairwise_add`, so it silently added
@(test)
simd_pairwise_aliases_are_distinct :: proc(t: ^testing.T) {
	a: #simd[2]i32 = {10, 3}
	b: #simd[2]i32 = {20, 4}

	add := simd.pairwise_add(a, b)
	sub := simd.pairwise_sub(a, b)
	testing.expect_value(t, intrinsics.simd_extract(add, 0), i32(13))
	testing.expect_value(t, intrinsics.simd_extract(sub, 0), i32(7))
	testing.expect_value(t, intrinsics.simd_extract(sub, 1), i32(16))
}

// The rotate offset is declared `$offset: int`; the checker demanded `i64`, so the declared
// spelling did not compile. Other integer types stay rejected -- the declaration is not #any_int.

@(test)
simd_lanes_rotate_offset_is_int :: proc(t: ^testing.T) {
	rot :: proc(v: #simd[4]u32, $offset: int) -> #simd[4]u32 {
		return intrinsics.simd_lanes_rotate_right(v, offset)
	}

	v: #simd[4]u32 = {0, 1, 2, 3}
	r := rot(v, 1)
	testing.expect_value(t, intrinsics.simd_extract(r, 0), u32(3))
	testing.expect_value(t, intrinsics.simd_extract(r, 1), u32(0))

	l := intrinsics.simd_lanes_rotate_left(v, 1)
	testing.expect_value(t, intrinsics.simd_extract(l, 0), u32(1))
	testing.expect_value(t, intrinsics.simd_extract(l, 3), u32(0))
}

// `simd_extract` / `simd_replace` declare a plain `idx: uint`, so a runtime index is allowed and
// lowers to a dynamic extractelement. Bounds are enforced only where the index is constant.

@(test)
simd_extract_accepts_a_runtime_index :: proc(t: ^testing.T) {
	v: #simd[4]u32 = {10, 20, 30, 40}
	i := 2
	testing.expect_value(t, intrinsics.simd_extract(v, i), u32(30))

	w := intrinsics.simd_replace(v, i, u32(99))
	testing.expect_value(t, intrinsics.simd_extract(w, 2), u32(99))
	testing.expect_value(t, intrinsics.simd_extract(w, 0), u32(10))
}

// simd_approx_recip and simd_approx_recip_sqrt

@(test)
simd_approx_recip :: proc(t: ^testing.T) {

	check_approx_recip_width :: proc(t: ^testing.T, $N: int, loc := #caller_location) {

		TOLERANCE :: 1e-3

		v: #simd[N]f32
		for i in 0..<N {
			v = intrinsics.simd_replace(v, i, f32(i + 1))
		}

		r := intrinsics.simd_approx_recip(v)
		s := intrinsics.simd_approx_recip_sqrt(v)
		for i in 0..<N {
			x := intrinsics.simd_extract(v, i)

			want := 1 / x
			got  := intrinsics.simd_extract(r, i)
			testing.expectf(t, abs(got - want) <= TOLERANCE * want,
				"simd_approx_recip(#simd[%d]f32) lane %d: got %v, want ~%v", N, i, got, want, loc = loc)

			want_sqrt := 1 / math.sqrt(x)
			got_sqrt  := intrinsics.simd_extract(s, i)
			testing.expectf(t, abs(got_sqrt - want_sqrt) <= TOLERANCE * want_sqrt,
				"simd_approx_recip_sqrt(#simd[%d]f32) lane %d: got %v, want ~%v", N, i, got_sqrt, want_sqrt, loc = loc)
		}
	}

	check_approx_recip_width(t, 1)
	check_approx_recip_width(t, 2)
	check_approx_recip_width(t, 4)
	check_approx_recip_width(t, 8)
	check_approx_recip_width(t, 16)
	check_approx_recip_width(t, 32)
	check_approx_recip_width(t, 64)
}
