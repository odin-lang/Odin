// `#soa_split` takes a struct or an array of length 4 or below, and not inside a `struct #raw_union`.
// `soa_zip` cannot make the columns of a `#soa_split` field.
package test_issue_soa_split_errors

V :: struct {
	x, y: f32,
}

U :: struct #raw_union {
	a: f32,
	b: u32,
}

Bad_Types :: struct {
	#soa_split a: f32,
	#soa_split b: [5]f32,
	#soa_split c: U,
	#soa_split d: #soa[4]V,
	#soa_split e: ^V,
}

Bad_Context :: struct #raw_union {
	#soa_split v: V,
	x:            f64,
}

Poly :: struct($T: typeid) {
	#soa_split v: T,
}

Good :: struct {
	#soa_split v: V,
	#soa_split l: [4]f32,
}

main :: proc() {
	a: Bad_Types
	b: Bad_Context
	c: Poly(V)
	d: Poly(f32)
	e: Good

	// `soa_zip` cannot make a slice of a `#soa_split` field's values into its columns
	vs: []V
	ls: [][4]f32
	f: #soa[]Good = soa_zip(v = vs, l = ls)
	_, _, _, _, _, _ = a, b, c, d, e, f
}
