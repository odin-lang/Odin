// Field tags are part of a bit_field's type, as they are for a struct:
// only `b1 = b2` must fail to compile.
package test_issue_bit_field_tag_identity

assign :: proc() {
	b1: bit_field u8 {x: u8 | 4 `tag:"one"`}
	b2: bit_field u8 {x: u8 | 4 `tag:"two"`}
	b1 = b2

	b3: bit_field u8 {x: u8 | 4 `tag:"one"`}
	b1 = b3

	b4: bit_field u8 {x: u8 | 4}
	b5: bit_field u8 {x: u8 | 4}
	b4 = b5

	_, _, _ = b1, b3, b4
}
