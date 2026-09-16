// Tests issue #7336 https://github.com/odin-lang/Odin/issues/7336
package test_issues

import "core:testing"

S :: struct {
	a: [dynamic; 1]matrix[4, 4]f32,
	b: matrix[4, 4]f32,
}

@(test)
test_offset :: proc(t: ^testing.T) {
	s := new(S)
	defer free(s)

	// 4*4 f32 + dynamic len == 72
	expect: uintptr = 4 * 4 * 4 + size_of(int)
	testing.expect(t, offset_of(S, b) == expect)
	testing.expect(t, uintptr(rawptr(&s.b)) - uintptr(rawptr(s)) == expect)
}
