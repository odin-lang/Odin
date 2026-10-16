// Tests issue #7901 https://github.com/odin-lang/Odin/issues/7901
// Unbounded polymorphic record instantiation must report an error instead of crashing
package test_issue_7901

Offset_Check :: struct($T: typeid) where offset_of(Offset_Check([2]T), val) == 0 {
	val: T,
}

Recursive_Node :: struct($N: int) {
	val:  int,
	next: ^Recursive_Node(N - 1),
}

main :: proc() {
	_ = Offset_Check(int){val = 5}

	n: Recursive_Node(3)
	_ = n
}
