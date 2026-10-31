#+vet !shadowing
package test_internal

import "core:testing"

// `x := call()` lets the callee write its sret result straight into `x`.
// Each case must give the same result as copying the result into `x` after the call.

@(private="file")
Big :: struct {
	a, b, c, d: int,
	tag:        u8,
}

@(private="file")
make_big :: #force_no_inline proc(n: int) -> Big {
	return {n, n+1, n+2, n+3, u8(n)}
}

@(private="file")
shift_big :: #force_no_inline proc(v: Big) -> Big {
	return {v.a+1, v.b+1, v.c+1, v.d+1, v.tag+1}
}

@(private="file")
shift_big_ptr :: #force_no_inline proc(v: ^Big) -> Big {
	return {v.a+1, v.b+1, v.c+1, v.d+1, v.tag+1}
}

@(test)
test_rvo_declaration_value :: proc(t: ^testing.T) {
	x := make_big(5)
	testing.expect_value(t, x, Big{5, 6, 7, 8, 5})

	f := make_big
	y := f(9)
	testing.expect_value(t, y, make_big(9))

	@(align=64) z := make_big(7)
	testing.expect_value(t, uintptr(&z) % 64, 0)
	testing.expect_value(t, z, make_big(7))
}

@(test)
test_rvo_declaration_shadowing :: proc(t: ^testing.T) {
	x := make_big(1)
	{
		x := shift_big(x)
		testing.expect_value(t, x, make_big(2))
	}
	{
		x := shift_big_ptr(&x)
		testing.expect_value(t, x, make_big(2))
	}
	testing.expect_value(t, x, make_big(1))
}

@(private="file")
write_other :: #force_no_inline proc(other: ^Big, n: int) -> Big {
	other.a = -n
	r := make_big(n)
	r.b = other.a
	return r
}

@(test)
test_rvo_declaration_other_pointer :: proc(t: ^testing.T) {
	y: Big
	x := write_other(&y, 3)
	testing.expect_value(t, x, Big{3, -3, 5, 6, 3})
	testing.expect_value(t, y.a, -3)
}

@(test)
test_rvo_declaration_loop :: proc(t: ^testing.T) {
	prev: Big
	for i in 0..<4 {
		x := shift_big(prev)
		x.d += i
		prev = x
	}
	testing.expect_value(t, prev, Big{4, 4, 4, 10, 4})
}

@(private="file")
named_result :: #force_no_inline proc(n: int, seen: ^Big) -> (r: Big) {
	seen^ = r
	r.a = n
	r.b = r.a * 2
	return
}

@(private="file")
named_defer :: #force_no_inline proc(n: int) -> (r: Big) {
	defer r.d = 100
	return make_big(n)
}

@(private="file")
named_early :: #force_no_inline proc(n: int) -> (r: Big) {
	r.a = 1
	if n > 0 {
		return make_big(n)
	}
	r.b = 2
	return
}

@(test)
test_rvo_declaration_named_result :: proc(t: ^testing.T) {
	seen := make_big(9)
	x := named_result(3, &seen)
	testing.expect_value(t, seen, Big{})
	testing.expect_value(t, x, Big{3, 6, 0, 0, 0})

	// Defers run after the results are taken. They must not reach `y`.
	y := named_defer(1)
	testing.expect_value(t, y, make_big(1))

	z := named_early(3)
	testing.expect_value(t, z, make_big(3))
	w := named_early(0)
	testing.expect_value(t, w, Big{1, 2, 0, 0, 0})
}

@(private="file")
Rvo_Error :: enum {
	None,
	Bad,
}

@(private="file")
check_positive :: proc(n: int) -> Rvo_Error {
	return .Bad if n < 0 else .None
}

@(private="file")
named_multi :: #force_no_inline proc(n: int) -> (r: Big, ok: bool) {
	defer if ok {
		r.c = -1
	}
	r = make_big(n)
	ok = n > 0
	return
}

@(private="file")
named_or_return :: #force_no_inline proc(n: int) -> (r: Big, err: Rvo_Error) {
	r = make_big(n)
	check_positive(n) or_return
	r.a = 99
	return
}

@(test)
test_rvo_declaration_named_multiple_results :: proc(t: ^testing.T) {
	x, ok := named_multi(2)
	testing.expect_value(t, x, make_big(2))
	testing.expect(t, ok)

	y, ok2 := named_multi(-1)
	testing.expect_value(t, y, make_big(-1))
	testing.expect(t, !ok2)

	z, err := named_or_return(-2)
	testing.expect_value(t, z, make_big(-2))
	testing.expect_value(t, err, Rvo_Error.Bad)

	w, err2 := named_or_return(2)
	testing.expect_value(t, w, Big{99, 3, 4, 5, 2})
	testing.expect_value(t, err2, Rvo_Error.None)
}

@(private="file")
forward_call :: #force_no_inline proc(n: int) -> Big {
	return make_big(n*2)
}

@(private="file")
declare_and_return :: #force_no_inline proc(n: int) -> Big {
	y := make_big(n)
	y.d = -y.d
	return y
}

@(private="file")
fib_big :: #force_no_inline proc(n: int) -> Big {
	if n < 2 {
		return {n, 0, 0, 0, 0}
	}
	x := fib_big(n-1)
	y := fib_big(n-2)
	return {x.a + y.a, x.a, y.a, n, u8(n)}
}

@(private="file")
inline_big :: #force_inline proc(n: int) -> (r: Big) {
	r.a = n
	r.d = n*n
	return
}

@(private="file")
make_array :: #force_no_inline proc($N: int, v: int) -> (r: [N]int) {
	for &e, i in r {
		e = v + i
	}
	return
}

@(test)
test_rvo_declaration_callees :: proc(t: ^testing.T) {
	x := forward_call(2)
	testing.expect_value(t, x, make_big(4))

	y := declare_and_return(3)
	testing.expect_value(t, y, Big{3, 4, 5, -6, 3})

	z := fib_big(10)
	testing.expect_value(t, z, Big{55, 34, 21, 10, 10})

	w := inline_big(4)
	testing.expect_value(t, w, Big{4, 0, 0, 16, 0})

	v := make_array(8, 3)
	testing.expect_value(t, v, [8]int{3, 4, 5, 6, 7, 8, 9, 10})
}

@(private="file")
Rvo_Union :: union {
	Big,
	int,
}

@(private="file")
make_union :: #force_no_inline proc(big: bool) -> Rvo_Union {
	if big {
		return make_big(6)
	}
	return 6
}

@(private="file")
make_matrix :: #force_no_inline proc(s: f32) -> matrix[4, 4]f32 {
	return s
}

@(test)
test_rvo_declaration_types :: proc(t: ^testing.T) {
	u := make_union(true)
	testing.expect_value(t, u, Rvo_Union(make_big(6)))
	v := make_union(false)
	testing.expect_value(t, v, Rvo_Union(6))

	m := make_matrix(2)
	want: matrix[4, 4]f32 = 2
	testing.expect_value(t, m, want)
}

@(private="file")
g_rvo_released:       [4]int
@(private="file")
g_rvo_released_count: int

@(private="file")
release_big :: proc(v: Big) {
	g_rvo_released[g_rvo_released_count] = v.a
	g_rvo_released_count += 1
}

@(private="file")
release_big_ptr :: proc(v: ^Big) {
	g_rvo_released[g_rvo_released_count] = v.a
	g_rvo_released_count += 1
}

@(private="file", deferred_out=release_big)
acquire_big :: #force_no_inline proc(n: int) -> Big {
	return make_big(n)
}

@(private="file", deferred_out_by_ptr=release_big_ptr)
acquire_big_ptr :: #force_no_inline proc(n: int) -> Big {
	return make_big(n)
}

@(private="file")
return_acquired :: #force_no_inline proc(n: int) -> Big {
	return acquire_big(n)
}

// A deferred procedure gets the result as it was when the call returned, and `return call()` still runs it
@(test)
test_rvo_declaration_deferred_out :: proc(t: ^testing.T) {
	g_rvo_released_count = 0
	{
		x := acquire_big(1)
		x.a = 100
	}
	{
		y := acquire_big_ptr(2)
		y.a = 200
	}
	z := return_acquired(3)
	testing.expect_value(t, z, make_big(3))
	testing.expect_value(t, g_rvo_released_count, 3)
	testing.expect_value(t, g_rvo_released, [4]int{1, 2, 3, 0})
}
