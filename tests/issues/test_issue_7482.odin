// Tests issue #7482 and #7474: a polymorphic procedure from another package used as a
// procedure value crashed the backend with `addr.addr.value != nullptr`.
// https://github.com/odin-lang/Odin/issues/7482
package test_issues

import "core:sort"

apply :: proc(how: proc(a: []int), what: []int) {
	how(what)
}

main :: proc() {
	a := [3]int{3, 1, 2}
	apply(sort.quick_sort, a[:])
	assert(a == {1, 2, 3})

	b := [3]int{2, 3, 1}
	f: proc(a: []int) = (sort.quick_sort)
	f(b[:])
	assert(b == {1, 2, 3})
}
