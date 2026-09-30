// Tests issue #7596 and #7511: a procedure literal converted to a union variant inside a
// compound literal crashed the backend with `value_type != nullptr`.
// https://github.com/odin-lang/Odin/issues/7596
package test_issues

P :: proc() -> int
U :: union {P, int}
S :: struct {
	u: U,
	m: Maybe(P),
}

global_slice := []U{proc() -> int { return 1 }, 2}
global_struct := S{u = proc() -> int { return 3 }, m = proc() -> int { return 4 }}

main :: proc() {
	local := [1]U{proc() -> int { return 5 }}

	assert(global_slice[0].(P)() == 1)
	assert(global_slice[1].(int) == 2)
	assert(global_struct.u.(P)() == 3)
	assert(global_struct.m.?() == 4)
	assert(local[0].(P)() == 5)
}
