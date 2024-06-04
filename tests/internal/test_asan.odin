// Intended to contain code that would trigger asan easily if the abi was set up badly.
package test_asan

import "core:testing"

@(test)
test_12_bytes :: proc(t: ^testing.T) {
	internal :: proc() -> (a, b: f32, ok: bool) {
		return max(f32), 0, true
	}

	a, b, ok := internal()
	testing.expectf(t, a == max(f32), "a (%v) != max(f32)", a)
	testing.expectf(t, b == 0,        "b (%v) != 0", b)
	testing.expectf(t, ok,            "ok (%v) != true", ok)
}

@(test)
test_12_bytes_two :: proc(t: ^testing.T) {
	internal :: proc() -> (a: f32, b: int) {
		return 100., max(int)
	}

	a, b := internal()
	testing.expectf(t, a == 100.,     "a (%v) != 100.", a)
	testing.expectf(t, b == max(int), "b (%v) != max(int)", b)
}
