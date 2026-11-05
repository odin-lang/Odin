// Globals are defined and initialized in the module of their own package
package test_issue_split_globals

import "core:testing"
import "other"
import "other/data"

C := other.A + 10*other.B
D := other.next() + 0*C
E := data.PTR^
F := other.callback()
G := other.P_ptr
H := &other.TABLE

init_counter: int

@(init)
record_counter :: proc "contextless" () {
	init_counter = other.counter
}

@(test)
test_split_globals :: proc(t: ^testing.T) {
	values := [4]int{other.A, other.B, other.get_internal(), D}
	seen: [5]bool
	for v in values {
		testing.expect(t, 1 <= v && v <= 4)
		if 1 <= v && v <= 4 {
			testing.expect(t, !seen[v])
			seen[v] = true
		}
	}
	testing.expect(t, D > other.A && D > other.B)
	testing.expect_value(t, C, other.A + 10*other.B)
	testing.expect_value(t, other.counter, 4)
	testing.expect_value(t, init_counter, 4)

	testing.expect_value(t, E, 20)
	testing.expect_value(t, data.PTR, &data.VALUES[1])
	testing.expect_value(t, F, 7)
	testing.expect_value(t, G, &other.P)
	testing.expect_value(t, H^[0], &other.P)
	testing.expect_value(t, other.boxed^, other.Point{3, 4})
	testing.expect_value(t, other.NAMES[2], "z")
	testing.expect_value(t, other.RO[3], 4)
	testing.expect_value(t, other.any_p.(other.Point), other.Point{1, 2})
}
