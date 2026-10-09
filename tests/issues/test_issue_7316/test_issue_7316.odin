// Tests issue #7316 https://github.com/odin-lang/Odin/issues/7316
// A polymorphic procedure in a constant compound literal is its instance, not nil
package test_issues

import "core:testing"

Foo :: struct($N: int) {
	data:   [N]u8,
	number: int,
	update: proc(f: ^Foo(N), delta: int),
	get:    proc(f: Foo(N)) -> int,
}

foo_update :: proc(f: ^Foo($N), delta: int) { f.number += delta }
foo_get    :: proc(f: Foo($N)) -> int { return f.number }

foo_init :: proc(f: ^Foo($N)) {
	f^ = {
		number = 333,
		update = foo_update,
		get    = foo_get,
	}
}

identity :: proc(x: $T) -> T { return x }

global_foo   := Foo(4){number = 1, update = foo_update, get = foo_get}
global_procs := [2]proc(int) -> int{identity, identity}

@(test)
test_issue_7316 :: proc(t: ^testing.T) {
	f: Foo(10)
	foo_init(&f)
	testing.expect(t, f.update != nil)
	testing.expect(t, f.get != nil)
	f.update(&f, 5)
	testing.expect_value(t, f.get(f), 338)

	g := Foo(10){number = 1, update = foo_update}
	testing.expect(t, g.update != nil)

	procs := [2]proc(int) -> int{identity, identity}
	testing.expect_value(t, procs[1](7), 7)

	testing.expect(t, global_foo.update != nil)
	testing.expect_value(t, global_procs[0](9), 9)
}
