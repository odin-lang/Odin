// Tests issue #5097 https://github.com/odin-lang/Odin/issues/5097
package test_issues

Node_Ptr :: ^Node // the typedef...

Node :: struct {
	prev, next: Node_Ptr, // replacing the type with ^Node also fixes it
}

// ...if placed here, it works just fine

main :: proc() {
	node: Node_Ptr
	_ = node
}
