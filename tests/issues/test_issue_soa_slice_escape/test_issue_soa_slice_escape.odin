// A slice of a local `#soa[N]T` or `#soa[dynamic; N]T` refers to its stack memory, as does an #soa slice literal.
// An #soa pointer, `&s[i]`, holds the address of the #soa array `s` itself.
package test_issue_soa_slice_escape

P :: struct {
	x, y: f32,
}

Q :: struct {
	#soa_split pos: P,
	id:             int,
}

fixed_slice :: proc() -> #soa[]P {
	a: #soa[4]P
	return a[:]
}

fixed_capacity_slice :: proc() -> #soa[]P {
	c: #soa[dynamic; 4]P
	append(&c, P{1, 2})
	return c[:]
}

through_local :: proc() -> #soa[]P {
	a: #soa[4]P
	s := a[1:]
	return s
}

literal :: proc() -> #soa[]P {
	return #soa[]P{{1, 2}, {3, 4}}
}

literal_runtime :: proc(n: f32) -> #soa[]P {
	return #soa[]P{{n, 2}}
}

element_of_slice :: proc(d: #soa[]P) -> #soa^#soa[]P {
	return &d[:][1]
}

element_of_view :: proc(d: #soa[]Q) -> #soa^#soa[]P {
	return &d.pos[1]
}

element_of_dynamic :: proc() -> #soa^#soa[dynamic]P {
	d: #soa[dynamic]P
	append(&d, P{1, 2})
	return &d[0]
}

element_of_parameter :: proc(d: #soa[]P) -> #soa^#soa[]P {
	return &d[1]
}

// Not errors
element_through_pointer :: proc(d: ^#soa[dynamic]P) -> #soa^#soa[dynamic]P {
	return &d[0]
}

field_of_dynamic :: proc() -> ^f32 {
	d: #soa[dynamic]P
	append(&d, P{1, 2})
	return &d[0].x
}

heap_slice :: proc(d: ^#soa[dynamic]P) -> #soa[]P {
	return d[:]
}

pointer_slice :: proc(a: ^#soa[4]P) -> #soa[]P {
	return a[:]
}

dynamic_local :: proc() -> #soa[]P {
	d: #soa[dynamic]P
	append(&d, P{1, 2})
	return d[:]
}

main :: proc() {
	_ = fixed_slice()
	_ = fixed_capacity_slice()
	_ = through_local()
	_ = literal()
	_ = literal_runtime(1)
	d: #soa[dynamic]P
	_ = heap_slice(&d)
	a: #soa[4]P
	_ = pointer_slice(&a)
	_ = dynamic_local()
	_ = element_of_slice
	_ = element_of_view
	_ = element_of_dynamic
	_ = element_of_parameter
	_ = element_through_pointer
	_ = field_of_dynamic
}
