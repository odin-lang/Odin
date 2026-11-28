package test_internal

import "core:testing"

@(private="file")
Soa_Point :: struct {
	x, y: f32,
}

@(private="file")
Soa_Points :: #soa[3]Soa_Point

@(private="file")
soa_count_value :: proc(p: #soa[$N]Soa_Point) -> int {
	return N
}

@(private="file")
soa_count_pointer :: proc(p: ^#soa[$N]Soa_Point) -> int {
	p.x[N-1] = f32(N)
	return N
}

@(private="file")
soa_count_and_elem :: proc(p: ^#soa[$N]$T) -> (int, typeid) {
	return N, T
}

@(private="file")
soa_elem_only :: proc(p: #soa[4]$T) -> int {
	return len(p)
}

@(private="file")
soa_count_in_result :: proc(p: #soa[$N]Soa_Point) -> (xs: [N]f32) {
	for i in 0..<N {
		xs[i] = p.x[i]
	}
	return
}

// `$N` in `#soa[$N]T` is inferred like `$N` in `[$N]T`, and a written count is kept for a polymorphic `T`
@(test)
test_soa_poly_count :: proc(t: ^testing.T) {
	four:  #soa[4]Soa_Point
	seven: #soa[7]Soa_Point
	named: Soa_Points

	testing.expect_value(t, soa_count_value(four),  4)
	testing.expect_value(t, soa_count_value(seven), 7)
	testing.expect_value(t, soa_count_value(named), 3)

	testing.expect_value(t, soa_count_pointer(&seven), 7)
	testing.expect_value(t, seven.x[6], 7)

	n, type := soa_count_and_elem(&four)
	testing.expect_value(t, n, 4)
	testing.expect_value(t, type, typeid_of(Soa_Point))

	testing.expect_value(t, soa_elem_only(four), 4)

	seven.x[2] = 2.5
	xs := soa_count_in_result(seven)
	testing.expect_value(t, len(xs), 7)
	testing.expect_value(t, xs[2], 2.5)
}
