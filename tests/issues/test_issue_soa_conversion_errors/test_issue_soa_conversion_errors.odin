// `#soa[N]T` and `[N]T` convert only at the same length and element type, and #soa slices only through `copy`
package test_issue_soa_conversion_errors

P :: struct {
	x, y: f32,
}

Q :: struct {
	x, y: f32,
}

main :: proc() {
	a: [4]P
	s: #soa[4]P
	sl: []P
	ss: #soa[]P

	_ = (#soa[3]P)(a)  // length
	_ = (#soa[4]Q)(a)  // element type
	_ = ([5]P)(s)      // length
	_ = (#soa[]P)(sl)  // slices
	_ = ([]P)(ss)      // slices

	// Allowed
	_ = (#soa[4]P)(a)
	_ = ([4]P)(s)
}
