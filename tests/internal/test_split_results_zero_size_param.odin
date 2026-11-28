package test_internal

import "core:testing"

// On i386 a zero-size argument has no LLVM parameter. The pointers that a split multiple-value
// result is returned through sit one parameter earlier per empty argument.
// Taking them from the argument count stored the results through the context pointer.

@(private="file")
Empty :: struct {}

@(private="file")
deferred_count: int

@(private="file")
named_results :: proc(a: []i64, e: Empty) -> (first: i64, flag: bool) {
	first = a[1]
	flag  = true
	return
}

@(private="file")
named_results_with_defer :: proc(a: []i64, e: Empty) -> (first: i64, flag: bool) {
	defer deferred_count += 1
	first = a[1]
	flag  = true
	return
}

@(private="file")
unnamed_results :: proc(e: Empty, a: []int, f: Empty) -> (int, int, int) {
	return a[0], a[1], a[2]
}

@(private="file")
generic_results :: proc(a: []$E, call: $P) -> (E, bool) {
	return a[2], true
}

@test
test_split_results_zero_size_param :: proc(t: ^testing.T) {
	allocator := context.allocator

	wide  := []i64{10, 20, 30}
	small := []int{1, 2, 3}

	first, flag := named_results(wide, {})
	second, second_flag := named_results_with_defer(wide, {})
	x, y, z := unnamed_results({}, small, {})
	g, ok := generic_results(wide, struct{}{})

	testing.expect(t, context.allocator.procedure == allocator.procedure && context.allocator.data == allocator.data, "a result was stored through the context pointer")

	testing.expect_value(t, first, 20)
	testing.expect_value(t, flag, true)
	testing.expect_value(t, second, 20)
	testing.expect_value(t, second_flag, true)
	testing.expect_value(t, deferred_count, 1)
	testing.expect_value(t, x, 1)
	testing.expect_value(t, y, 2)
	testing.expect_value(t, z, 3)
	testing.expect_value(t, g, 30)
	testing.expect_value(t, ok, true)
}
