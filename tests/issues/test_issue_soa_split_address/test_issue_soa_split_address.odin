// A `#soa_split` field of an #soa element has no address, only its own fields do
#+feature using-stmt
package test_issue_soa_split_address

V :: struct {
	x, y: f32,
}

P :: struct {
	#soa_split v: V,
	#soa_split l: [2]f32,
	w:            V,
}

N :: struct {
	#soa_split p: P,
}

main :: proc() {
	s: #soa[4]P
	_ = &s[0].v
	_ = &s[0].l

	for &e in s {
		_ = &e.v
		using e
		_ = &v
	}

	sp := &s[1]
	_ = &sp.v
	_ = &sp^.v

	n: #soa[2]N
	_ = &n[0].p
	_ = &n[0].p.v

	// fine
	_ = &s[0].v.x
	_ = &s[0].l[1]
	_ = &s[0].w
	_ = &n[0].p.v.y
	_ = &n[0].p.w
	q: P
	_ = &q.v
	a: #soa[2][2]P
	_ = &a[0][1].v
}
