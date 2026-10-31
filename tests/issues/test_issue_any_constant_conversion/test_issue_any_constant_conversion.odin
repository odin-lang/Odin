// Converting a constant to `any` must box the value, as converting a variable does.
// The result used to stay a constant of type `any`: the backend emitted a nil `any`, failed an assertion, or crashed.
package test_issue_any_constant_conversion

import "core:testing"

@(private="file")
Kind :: enum {
	A,
	B,
}

@(private="file")
Holder :: struct {
	v: any,
}

@(test)
test_any_constant_conversion :: proc(t: ^testing.T) {
	X :: 5

	a := any(f64(1.5))
	b := any(1)
	c := any("str")
	d := any(true)
	e := any(Kind.B)
	f := cast(any)X

	testing.expect_value(t, a.id, typeid_of(f64))
	testing.expect_value(t, b.id, typeid_of(int))
	testing.expect_value(t, c.id, typeid_of(string))
	testing.expect_value(t, d.id, typeid_of(bool))
	testing.expect_value(t, e.id, typeid_of(Kind))
	testing.expect_value(t, f.id, typeid_of(int))

	testing.expect_value(t, a.(f64),    1.5)
	testing.expect_value(t, b.(int),    1)
	testing.expect_value(t, c.(string), "str")
	testing.expect_value(t, d.(bool),   true)
	testing.expect_value(t, e.(Kind),   Kind.B)
	testing.expect_value(t, f.(int),    5)
}

@(test)
test_any_constant_conversion_in_literals :: proc(t: ^testing.T) {
	values := [?]any{any(2), 3}
	holder := Holder{any(f32(7))}

	testing.expect_value(t, values[0].(int), 2)
	testing.expect_value(t, values[1].(int), 3)
	testing.expect_value(t, holder.v.(f32),  7)
}
