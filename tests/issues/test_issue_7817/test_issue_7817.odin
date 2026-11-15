package test_issue_7817

import "core:testing"

// A polymorphic union instantiated with a still-polymorphic record operand, such as `Maybe(Box($T))` in a
// procedure signature, checked its variants as if the operand were concrete, and reported a non-specialized
// polymorphic type inside the union's declaration. A struct in the same position skips its fields.

Box :: struct($T: typeid) {
	value: T,
}

Either :: union($T: typeid) #no_nil {
	T,
	Box(T),
}

unwrap :: proc(m: Maybe(Box($T))) -> (T, bool) {
	b, ok := m.?
	return b.value, ok
}

depth :: proc(e: Either(Box($T))) -> int {
	switch _ in e {
	case Box(T):      return 1
	case Box(Box(T)): return 2
	}
	return 0
}

@(test)
test_maybe_of_poly_record :: proc(t: ^testing.T) {
	v, ok := unwrap(Maybe(Box(int))(Box(int){42}))
	testing.expect_value(t, v, 42)
	testing.expect_value(t, ok, true)

	s, s_ok := unwrap(Maybe(Box(string)){})
	testing.expect_value(t, s, "")
	testing.expect_value(t, s_ok, false)
}

@(test)
test_no_nil_union_of_poly_record :: proc(t: ^testing.T) {
	testing.expect_value(t, depth(Either(Box(int))(Box(int){1})), 1)
	testing.expect_value(t, depth(Either(Box(int))(Box(Box(int)){})), 2)
}
