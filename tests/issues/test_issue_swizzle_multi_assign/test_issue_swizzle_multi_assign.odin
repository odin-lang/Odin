package test_issues

import "core:testing"

// A multi-assignment reads every right-hand side before it stores into any target, which is what
// makes `a, b = b, a` a swap. Storing into a swizzle reused the address the source was loaded from
// instead of the value read at that point, so a source that named a target written earlier in the
// same statement read back the new contents.

@(test)
swizzle_multi_assign_swap :: proc(t: ^testing.T) {
	v := [4]f32{1, 2, 3, 4}
	v.xy, v.zw = v.zw, v.xy
	testing.expect_value(t, v, [4]f32{3, 4, 1, 2})

	// the other order happened to be correct already
	w := [4]f32{1, 2, 3, 4}
	w.zw, w.xy = w.xy, w.zw
	testing.expect_value(t, w, [4]f32{3, 4, 1, 2})

	x := [4]f32{1, 2, 3, 4}
	x.xy, x.wz = x.wz, x.xy
	testing.expect_value(t, x, [4]f32{4, 3, 2, 1})
}

@(test)
swizzle_multi_assign_element_types :: proc(t: ^testing.T) {
	a := [4]i32{1, 2, 3, 4}
	a.xy, a.zw = a.zw, a.xy
	testing.expect_value(t, a, [4]i32{3, 4, 1, 2})

	b := [4]f64{1, 2, 3, 4}
	b.xy, b.zw = b.zw, b.xy
	testing.expect_value(t, b, [4]f64{3, 4, 1, 2})

	c := [4]u8{1, 2, 3, 4}
	c.xy, c.zw = c.zw, c.xy
	testing.expect_value(t, c, [4]u8{3, 4, 1, 2})
}

@(test)
swizzle_multi_assign_through_pointer :: proc(t: ^testing.T) {
	v := [4]f32{1, 2, 3, 4}
	p := &v
	p.xy, p.zw = p.zw, p.xy
	testing.expect_value(t, v, [4]f32{3, 4, 1, 2})
}

@(test)
swizzle_multi_assign_across_variables :: proc(t: ^testing.T) {
	// the source names a different variable, which an earlier store still writes to
	a := [4]f32{1, 2, 3, 4}
	b := [4]f32{5, 6, 7, 8}
	a.xy, b.xy = b.xy, a.xy
	testing.expect_value(t, a, [4]f32{5, 6, 3, 4})
	testing.expect_value(t, b, [4]f32{1, 2, 7, 8})
}

@(test)
swizzle_multi_assign_three_targets :: proc(t: ^testing.T) {
	v := [4]f32{1, 2, 3, 4}
	v.xy, v.zw, v.x = v.zw, v.xy, v.w
	testing.expect_value(t, v, [4]f32{4, 4, 1, 2})
}

@(test)
swizzle_single_assign_unchanged :: proc(t: ^testing.T) {
	// one target still reads every lane before it writes any of them
	v := [4]f32{1, 2, 3, 4}
	v.yzw = v.xyz
	testing.expect_value(t, v, [4]f32{1, 1, 2, 3})

	w := [4]f32{1, 2, 3, 4}
	w.xy = w.zw
	testing.expect_value(t, w, [4]f32{3, 4, 3, 4})

	x := [4]f32{1, 2, 3, 4}
	x.x, x.y = x.y, x.x
	testing.expect_value(t, x, [4]f32{2, 1, 3, 4})
}
