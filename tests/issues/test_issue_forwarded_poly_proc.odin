package test_issues

import "core:testing"

// Passing a `$` proc parameter to another `$` parameter used to reuse the first instantiation,
// making every forwarding call run the procedure given to the first one.

apply   :: proc(v: ^int, $f: proc(^int)) { f(v) }
forward :: proc(v: ^int, $f: proc(^int)) { apply(v, f) }
twice   :: proc(v: ^int, $f: proc(^int)) { forward(v, f) }
one     :: proc(v: ^int) { v^ += 1 }
hundred :: proc(v: ^int) { v^ += 100 }

@(test)
forwarded_poly_proc :: proc(t: ^testing.T) {
	x := 0
	forward(&x, one)
	forward(&x, hundred)
	twice(&x, one)
	twice(&x, hundred)
	forward(&x, proc(v: ^int) { v^ += 1 })
	forward(&x, proc(v: ^int) { v^ += 100 })
	testing.expect_value(t, x, 303)
}
