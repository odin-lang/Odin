// A column of `#soa[dynamic; N]T` is a slice of the array's own storage, so the array must be addressable
#+feature using-stmt
package test_issue_soa_column_not_addressable

P :: struct {
	x, y: f32,
}

make_array :: proc() -> (c: #soa[dynamic; 4]P) {
	return
}

by_value :: proc(c: #soa[dynamic; 4]P) -> f32 {
	return c.x[0] + c[0].y
}

using_by_value :: proc(using c: #soa[dynamic; 4]P) -> int {
	return len(x)
}

using_by_pointer :: proc(using c: ^#soa[dynamic; 4]P) -> int {
	return len(x)
}

main :: proc() {
	c: #soa[dynamic; 4]P
	_ = by_value(c)
	_ = using_by_value(c)
	_ = using_by_pointer(&c)
	_ = make_array().x
}
