// A polymorphic procedure has no value until it is specialized. Casting or transmuting one
// was accepted and then hung the build or produced nil; each must be an error.

package test_issues

import "core:container/avl"

poly :: proc(a: $T) -> T { return a }

global := rawptr(avl.init_cmp)                       // error

main :: proc() {
	a := rawptr(poly)                                // error
	b := cast(proc(string, int))poly                 // error
	c := transmute(rawptr)poly                       // error

	// casting to a procedure type it can be specialized to still works
	d := cast(proc(int) -> int)poly
	_, _, _, _, _ = global, a, b, c, d
}
