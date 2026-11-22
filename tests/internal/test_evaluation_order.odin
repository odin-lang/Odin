package test_internal

import "core:slice"
import "core:testing"

// A value is read where it is evaluated, whatever its size.
// What the later operands of the same expression write cannot change it.
// Operands are still evaluated left to right.

@(private="file")
Big :: struct {
	v:   int,
	pad: [8]int,
}

@(private="file")
Three :: struct {
	a, b, c: int,
}

@(private="file")
Arr :: [16]int

@(private="file")
Vec :: [4]f32

@(private="file")
g_big: Big

@(private="file")
g_three: Three

@(private="file")
g_pair: [2]int

@(private="file")
g_arr: Arr

@(private="file")
g_vec: Vec

@(private="file")
mutate :: proc() -> int {
	g_big.v   = 99
	g_three.a = 99
	g_pair[0] = 99
	g_arr[0]  = 99
	g_vec[0]  = 99
	return 0
}

@(private="file")
set_v :: proc(b: ^Big) -> int {
	b.v = 99
	return 0
}

@(private="file")
bump :: proc(b: ^Big) -> Big {
	b.v += 1
	return b^
}

@(private="file")
bump_arr :: proc() -> Arr {
	g_arr[0] += 1
	return g_arr
}

@(private="file")
take_big :: #force_no_inline proc(b: Big, _: int) -> int {
	return b.v
}

@(private="file")
take_three :: #force_no_inline proc(v: Three, _: int) -> int {
	return v.a
}

@(private="file")
take_pair :: #force_no_inline proc(v: [2]int, _: int) -> int {
	return v[0]
}

@(private="file")
take_big_c :: #force_no_inline proc "c" (b: Big, _: int) -> int {
	return b.v
}

@(private="file")
take_two :: #force_no_inline proc(a, b: Big) -> int {
	return a.v*100 + b.v
}

@(private="file")
first_big :: #force_no_inline proc(args: ..Big) -> int {
	return args[0].v
}

@(private="file")
big_then_mutate :: #force_no_inline proc() -> (Big, int) {
	return g_big, mutate()
}

// These checks share the globals.
// Tests run in parallel: the checks are kept in one test.
@test
test_evaluation_order_values_read_where_evaluated :: proc(t: ^testing.T) {
	g_big.v = 1
	testing.expect_value(t, take_big(g_big, mutate()), 1)
	g_three.a = 1
	testing.expect_value(t, take_three(g_three, mutate()), 1)
	g_pair[0] = 1
	testing.expect_value(t, take_pair(g_pair, mutate()), 1)
	g_big.v = 1
	testing.expect_value(t, take_big_c(g_big, mutate()), 1)
	g_big.v = 1
	testing.expect_value(t, first_big(g_big, Big{v = mutate()}), 1)

	x: Big
	x.v = 1
	testing.expect_value(t, take_big(x, set_v(&x)), 1)

	p := &g_big
	g_big.v = 1
	testing.expect_value(t, take_big(p^, mutate()), 1)

	y: Big
	y.v = 1
	testing.expect_value(t, take_two(y, bump(&y)), 102)

	g_big.v = 1
	elems := [2]Big{g_big, {v = mutate()}}
	testing.expect_value(t, elems[0].v, 1)

	g_big.v = 1
	r, _ := big_then_mutate()
	testing.expect_value(t, r.v, 1)

	g_big.v = 1
	a, _ := g_big, mutate()
	testing.expect_value(t, a.v, 1)

	g_big = {}
	testing.expect_value(t, g_big == bump(&g_big), false)

	g_arr = {}
	sum := g_arr + bump_arr()
	testing.expect_value(t, sum[0], 1)

	g_vec = 1
	vec := g_vec + Vec{f32(mutate()), 0, 0, 0}
	testing.expect_value(t, vec[0], 1)
}

@(private="file")
g_order: [8]int

@(private="file")
g_order_len: int

@(private="file")
note :: proc(i: int) -> Big {
	g_order[g_order_len] = i
	g_order_len += 1
	return {v = i}
}

@(private="file")
note_int :: proc(i: int) -> int {
	return note(i).v
}

@(private="file")
expect_order :: proc(t: ^testing.T, want: []int, loc := #caller_location) {
	got := g_order[:g_order_len]
	testing.expectf(t, slice.equal(got, want), "evaluated %v, want %v", got, want, loc = loc)
	g_order_len = 0
}

@(private="file")
three_c :: #force_no_inline proc "c" (a: Big, b: int, c: Big) -> int {
	return a.v + b + c.v
}

@(private="file")
named :: #force_no_inline proc(a, b: Big) -> int {
	return a.v*10 + b.v
}

@test
test_evaluation_order_left_to_right :: proc(t: ^testing.T) {
	_ = take_two(note(1), note(2))
	expect_order(t, {1, 2})
	_ = three_c(note(1), note_int(2), note(3))
	expect_order(t, {1, 2, 3})
	_ = named(b = note(1), a = note(2))
	expect_order(t, {1, 2})
	_ = take_big(note(1), take_big(note(2), note_int(3)))
	expect_order(t, {1, 2, 3})
	_ = first_big(note(1), note(2), note(3))
	expect_order(t, {1, 2, 3})
	_ = [3]Big{note(1), note(2), note(3)}
	expect_order(t, {1, 2, 3})
	_ = note(1) == note(2)
	expect_order(t, {1, 2})
	a, b := note(1), note(2)
	_, _ = a, b
	expect_order(t, {1, 2})
}
