// An #soa dynamic array cannot be a compound literal, written out, through a type, or through an alias
package test_issue_soa_dynamic_literal

P :: struct {
	x, y: f32,
}

Particles :: #soa[dynamic]P

main :: proc() {
	a := #soa[dynamic]P{{1, 2}, {3, 4}}
	b: #soa[dynamic]P = {{1, 2}}
	c := Particles{{1, 2}}
	d := #soa[dynamic][2]f32{{1, 2}}

	// The empty literal is the zero value
	e := #soa[dynamic]P{}

	// The suggested form
	f: #soa[dynamic]P
	append(&f, #soa[]P{{1, 2}, {3, 4}})

	_, _, _, _, _ = a, b, c, d, e
	delete(f)
}
