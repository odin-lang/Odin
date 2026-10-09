package test_internal

import "core:testing"

// tests alignment of array arithmetic going through implicit vector casts

AlignHelper :: struct #min_field_align(16) {
	p: ^[4]f32,  // align 16 for the storage of the pointer
}

@(export)
array_arith_add_pointed :: #force_no_inline proc (a, b: ^AlignHelper) -> [4]f32 {
	return a.p^ + b.p^
}

@(export)
array_arith_neg_pointed :: #force_no_inline proc (a: ^AlignHelper) -> [4]f32 {
	return -a.p^
}

@(export)
array_arith_swizzle_pointed :: #force_no_inline proc (a: ^AlignHelper) -> [4]f32 {
	return a.p.wzyx
}

@(test)
array_arith_through_aligned_pointer_slot :: proc(t: ^testing.T) {
	@(align=16) buf := [8]f32{0, 1, 2, 3, 4, 5, 6, 7}
	h := AlignHelper{p = (^[4]f32)(&buf[1])}  // legit, [4]f32 is type align 4, buf[1] is align 4

	testing.expect_value(t, array_arith_add_pointed(&h, &h), [4]f32{2, 4, 6, 8})
	testing.expect_value(t, array_arith_neg_pointed(&h), [4]f32{-1, -2, -3, -4})
	testing.expect_value(t, array_arith_swizzle_pointed(&h), [4]f32{4, 3, 2, 1})
}
