package test_internal

import "core:testing"

U :: union { int, f64 }
Packed :: struct #packed { _: u8, arr: [2]int, u: U, fc: [dynamic; 4]int }

@(test)
test_packed_field_by_reference :: proc(t: ^testing.T) {
	p: Packed

	// array field of a #packed
	for &v in p.arr {
		v = 1
	}
	testing.expect_value(t, p.arr, [2]int{1, 1})

	#reverse for &v in p.arr {
		v = 2
	}
	testing.expect_value(t, p.arr, [2]int{2, 2})

	q := &p
	for &v in q.arr {
		v = 3
	}
	testing.expect_value(t, p.arr, [2]int{3, 3})

	// fixed capacity dyn array field of a #packed
	append(&p.fc, 1, 2)
	for &v in p.fc {
		v = 5
	}
	testing.expect_value(t, p.fc[0], 5)
	testing.expect_value(t, p.fc[1], 5)

	// type switch over a field of a #packed
	p.u = 1
	switch &v in p.u {
	case int: v = 42
	case f64: v = 0
	}
	testing.expect_value(t, p.u, U(42))

	// ptr to a variant of a union field of a #packed
	ptr := &p.u.(int)
	ptr^ = 7
	testing.expect_value(t, p.u, U(7))
}
