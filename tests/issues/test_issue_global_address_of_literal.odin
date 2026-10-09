// A global initialized with the address of a compound literal used to crash the backend
// if the literal's value was not a constant.
package test_issues

import "core:testing"

Holder     :: struct { target: ^int }
Outer      :: struct { inner: ^Inner }
Inner      :: struct { value: int }
Type       :: struct { variant: union { Array_Type } }
Array_Type :: struct { elem: ^Type }

initial_value :: proc "contextless" () -> int { return 42 }

number := 7

address_of_global := &Holder{target = &number}         // https://github.com/odin-lang/Odin/issues/4337
nested_literal    := &Outer{inner = &Inner{value = 3}} // https://github.com/odin-lang/Odin/issues/5950
value_from_call   := &Inner{value = initial_value()}   // https://github.com/odin-lang/Odin/issues/3995
union_variant     := &Type{variant = Array_Type{}}     // https://github.com/odin-lang/Odin/issues/7197
dynamic_array     := &[dynamic]int{}                   // https://github.com/odin-lang/Odin/issues/7640

@(test)
global_address_of_literal :: proc(t: ^testing.T) {
	testing.expect(t, address_of_global.target == &number)
	testing.expect_value(t, address_of_global.target^, 7)
	testing.expect_value(t, nested_literal.inner.value, 3)
	testing.expect_value(t, value_from_call.value, 42)

	_, is_array := union_variant.variant.(Array_Type)
	testing.expect(t, is_array)

	append(dynamic_array, 1)
	defer delete(dynamic_array^)
	testing.expect_value(t, len(dynamic_array), 1)
}
