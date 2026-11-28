// The length of a field of `#soa[dynamic; N]T` is only known at run time, so `#unroll for` needs a count, as for a slice
package test_issue_soa_field_unroll

V :: struct {
	x: f32,
}

main :: proc() {
	array: #soa[dynamic; 4]V
	#unroll for v in array.x {
		_ = v
	}
	#unroll(2) for v in array.x {
		_ = v
	}
}
