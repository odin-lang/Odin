// A value within a packed struct, passed to a procedure by reference, is passed by an address as aligned as its type
package test_issue_packed_field_by_value

import "core:testing"

Packed_Field_S :: struct { x: union { int, string }, y: u128 }
Packed_Field_P :: struct #packed { pad: u8, s: Packed_Field_S, arr: [2]Packed_Field_S }

// the address a value parameter is passed by
packed_field_address :: proc(s: Packed_Field_S) -> uintptr {
	a: any = s
	return uintptr(a.data)
}

packed_field_global: Packed_Field_P

@(test)
test_packed_field_by_value :: proc(t: ^testing.T) {
	p := Packed_Field_P{s = {x = 1, y = 2}, arr = {{x = 3}, {x = "four", y = 5}}}
	packed_field_global = p

	A :: align_of(Packed_Field_S)
	testing.expect_value(t, packed_field_address(p.s)                        % A, 0)
	testing.expect_value(t, packed_field_address(p.arr[1])                   % A, 0)
	testing.expect_value(t, packed_field_address(packed_field_global.s)      % A, 0)
	testing.expect_value(t, packed_field_address(packed_field_global.arr[1]) % A, 0)

	testing.expect_value(t, p.s,                        Packed_Field_S{x = 1, y = 2})
	testing.expect_value(t, p.arr[1],                   Packed_Field_S{x = "four", y = 5})
	testing.expect_value(t, packed_field_global.arr[0], Packed_Field_S{x = 3})
}
