// A column of a local `#soa[dynamic; N]T` refers to its stack memory
package test_issue_soa_column_escape

P :: struct {
	x, y: f32,
}

escapes :: proc() -> []f32 {
	c: #soa[dynamic; 4]P
	append(&c, P{1, 2})
	return c.x
}

through_pointer :: proc(c: ^#soa[dynamic; 4]P) -> []f32 {
	return c.x
}

main :: proc() {
	c: #soa[dynamic; 4]P
	_ = escapes()
	_ = through_pointer(&c)
}
