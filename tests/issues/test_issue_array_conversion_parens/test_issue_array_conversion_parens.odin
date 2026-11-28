// `[N]T(x)` is an array of `T(x)`, not a conversion: each gives one error, which suggests `([N]T)(x)`
package test_issue_array_conversion_parens

P :: struct {
	x, y: f32,
}

Poly :: struct($T: typeid) {
	v: T,
}

main :: proc() {
	aos: [4]P
	a := [4]P(aos)
	b := #soa[4]P(aos)
	c := []int(nil)
	_, _, _ = a, b, c

	// Not errors
	d: [4]Poly(int)
	e: #soa[4]Poly(f32)
	f: [4]type_of(aos[0])
	_, _, _ = d, e, f
}
