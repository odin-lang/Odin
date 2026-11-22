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

@(private="file")
g_write: proc()

@(private="file")
write_global :: proc() {
	g_big.a = 99
}

@(private="file")
write_through_proc_read :: #force_no_inline proc(v: Big) -> int {
	g_write()
	return v.a
}

@(private="file")
write_through_callee_read :: #force_no_inline proc(v: Big) -> int {
	write_global()
	return v.a
}

// writes nothing outside its own memory: a call to it needs no copy
@(private="file")
read_both :: #force_no_inline proc(v: Big, p: ^Big) -> int {
	return v.a*1000 + p.a
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

	g_big = {a = 1}
	g_write = write_global
	testing.expect_value(t, write_through_proc_read(g_big), 1)

	g_big = {a = 1}
	testing.expect_value(t, write_through_callee_read(g_big), 1)

	g_big = {a = 1}
	testing.expect_value(t, read_both(g_big, &g_big), 1001)
}

@(private="file")
g_kept: any

@(private="file")
keep_any :: proc(a: any) {
	g_kept = a
}

@(private="file")
write_kept_read :: #force_no_inline proc(v: Big) -> int {
	(^Big)(g_kept.data).a = 99
	return v.a
}

// An `any` given to an earlier call may be kept, and the value it refers to escapes.
// Only a variadic `..any` argument of a procedure which is not polymorphic is never kept past its call.
@(test)
test_by_value_params_kept_any :: proc(t: ^testing.T) {
	keep := keep_any // through a procedure value, which the stack-escape warning does not follow
	x := Big{a = 1}
	keep(x)
	testing.expect_value(t, write_kept_read(x), 1)
	g_kept = nil
}

@(private="file")
write_appended_read :: #force_no_inline proc(v: Big, list: ^[dynamic]any) -> int {
	(^Big)(list[0].data).a = 99
	return v.a
}

// A polymorphic procedure may keep its variadic arguments, e.g. `append_elems` with its `..E` as `..any`.
@(test)
test_by_value_params_appended_any :: proc(t: ^testing.T) {
	list: [dynamic]any
	defer delete(list)
	x := Big{a = 1}
	y := 2
	append(&list, x, y) // two values, so through the variadic `append_elems`
	testing.expect_value(t, write_appended_read(x, &list), 1)
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
