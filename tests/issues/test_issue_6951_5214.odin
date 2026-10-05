// Tests issues #6951 https://github.com/odin-lang/Odin/issues/6951
// and #5214 https://github.com/odin-lang/Odin/issues/5214
package test_issues

import "core:testing"

// Passing a `$` proc parameter to another `$` parameter used to reuse the first instantiation,
// making every forwarding call run the procedure given to the first one.

apply       :: proc(v: ^int, $f: proc(^int)) { f(v) }
forward     :: proc(v: ^int, $f: proc(^int)) { apply(v, f) }
twice       :: proc(v: ^int, $f: proc(^int)) { forward(v, f) }
apply_any   :: proc(v: ^int, $f: $F) { f(v) }
forward_any :: proc(v: ^int, $f: $F) { apply_any(v, f) }
one         :: proc(v: ^int) { v^ += 1 }
ten         :: proc "contextless" (v: ^int) { v^ += 10 }
hundred     :: proc(v: ^int) { v^ += 100 }

@(test)
forwarded_poly_proc :: proc(t: ^testing.T) {
	x := 0
	forward(&x, one)
	forward(&x, hundred)
	twice(&x, one)
	twice(&x, hundred)
	forward(&x, proc(v: ^int) { v^ += 1 })
	forward(&x, proc(v: ^int) { v^ += 100 })
	forward_any(&x, one)
	forward_any(&x, ten)
	testing.expect_value(t, x, 314)
}
