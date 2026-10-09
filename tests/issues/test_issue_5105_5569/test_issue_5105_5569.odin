// Tests issues #5105 https://github.com/odin-lang/Odin/issues/5105
// and #5569 https://github.com/odin-lang/Odin/issues/5569
package test_issues

import "core:sync"

// A procedure call with a deferred procedure is not allowed where it may not be evaluated.
// The associated deferred procedure would be called at the end of the scope regardless.

@(deferred_out = finish)
start :: proc(x: int) -> int { return x }
finish :: proc(_: int) {}

maybe :: proc(x: int) -> (int, bool) { return x, x > 0 }

m: sync.Mutex

main :: proc() {
	flag := true

	_ = start(1) if flag else 2    // Error
	_ = maybe(1) or_else start(2)  // Error
	switch {
	case flag, start(3) > 0:       // Error
	}
	if flag && sync.guard(&m) {}   // Error, `sync.guard` is a procedure group

	_ = start(4) + 1
}
