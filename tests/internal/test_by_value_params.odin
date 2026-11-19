package test_internal

import "core:testing"

// A parameter over 16 bytes keeps the value it had at the call, whatever the callee writes through other paths.

@(private="file")
Big :: struct {
	a, b, c, d: int,
	tag:        u8,
}

@(private="file")
g_big: Big

@(private="file")
g_stash: ^Big

@(private="file")
write_global_read :: #force_no_inline proc(v: Big) -> int {
	g_big.a = 99
	return v.a
}

@(private="file")
write_ptr_read :: #force_no_inline proc(v: Big, p: ^Big) -> int {
	p.a = 99
	return v.a
}

@(private="file")
write_stash_read :: #force_no_inline proc(v: Big) -> int {
	g_stash.a = 99
	return v.a
}

@(private="file")
write_any_read :: #force_no_inline proc(v: Big, a: any) -> int {
	(^Big)(a.data).a = 99
	return v.a
}

@(private="file")
forward :: #force_no_inline proc(v: Big) -> int {
	return write_global_read(v)
}

@(test)
test_by_value_params :: proc(t: ^testing.T) {
	g_big = {a = 1}
	testing.expect_value(t, write_global_read(g_big), 1)

	g_big = {a = 1}
	testing.expect_value(t, forward(g_big), 1)

	x := Big{a = 1}
	testing.expect_value(t, write_ptr_read(x, &x), 1)

	p := new(Big, context.temp_allocator)
	p.a = 1
	testing.expect_value(t, write_ptr_read(p^, p), 1)

	y := Big{a = 1}
	testing.expect_value(t, write_any_read(y, y), 1)
}

// The address is taken after the first call: the loop brings the call back round.
@(test)
test_by_value_params_address_taken_later :: proc(t: ^testing.T) {
	x: Big
	r := 0
	for i in 0..<2 {
		x.a = 1
		g_stash = &g_big
		if i == 1 {
			g_stash = &x
		}
		r += write_stash_read(x)
	}
	testing.expect_value(t, r, 2)
}
