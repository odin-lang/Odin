#+feature using-stmt
package test_internal

import "core:testing"

@(private="file")
P :: struct {
	x, y: f32,
}

@(private="file")
Holder :: struct {
	n:        int,
	using ps: #soa[]P,
}

@(private="file")
sum :: proc(xs: []f32) -> (total: f32) {
	for x in xs {
		total += x
	}
	return
}

@(private="file")
scale :: proc(using s: #soa[]P, k: f32) -> int {
	for &v in x {
		v *= k
	}
	return len(y)
}

// A column of an #soa slice or dynamic array is a slice of its `len` elements
@(test)
test_soa_columns_are_slices :: proc(t: ^testing.T) {
	d: #soa[dynamic]P
	defer delete(d)
	for i in 0..<5 {
		append(&d, P{f32(i), f32(10*i)})
	}

	testing.expect_value(t, typeid_of(type_of(d.x)), typeid_of([]f32))
	testing.expect_value(t, len(d.x), 5)
	testing.expect_value(t, sum(d.y), 100)
	testing.expect_value(t, raw_data(d.x), &d.x[0])

	for &x in d.x {
		x += 1
	}
	for x, i in d.x {
		testing.expect_value(t, x, f32(i) + 1)
	}

	d.y[1] = -1
	p := &d.y[2]
	p^ = -2
	testing.expect_value(t, d[1], P{2, -1})
	testing.expect_value(t, d[2], P{3, -2})

	sub := d.x[1:3]
	testing.expect_value(t, len(sub), 2)
	testing.expect_value(t, sub[0], 2)

	s := d[3:]
	testing.expect_value(t, len(s.x), 2)
	testing.expect_value(t, s.x[0], 4)

	pd := &d
	testing.expect_value(t, len(pd.y), 5)
	testing.expect_value(t, pd.x[4], 5)

	xs, ys := soa_unzip(d[:])
	testing.expect_value(t, raw_data(xs), raw_data(d.x))
	testing.expect_value(t, len(ys), len(d.y))

	empty: #soa[]P
	testing.expect_value(t, len(empty.x), 0)
}

// Columns reached through `using` are slices too
@(test)
test_soa_columns_using :: proc(t: ^testing.T) {
	d: #soa[dynamic]P
	defer delete(d)
	append(&d, P{1, 2}, P{3, 4})

	h := Holder{n = 1, ps = d[:]}
	testing.expect_value(t, len(h.x), 2)
	testing.expect_value(t, h.y[1], 4)

	testing.expect_value(t, scale(d[:], 2), 2)
	testing.expect_value(t, d.x[1], 6)
}

@(private="file")
scale_capped :: proc(using c: ^#soa[dynamic; 4]P, k: f32) -> int {
	for &v in y {
		v *= k
	}
	return len(x)
}

// The columns of `#soa[N]T` are its arrays
@(test)
test_soa_columns_fixed :: proc(t: ^testing.T) {
	fixed: #soa[4]P
	testing.expect_value(t, typeid_of(type_of(fixed.x)), typeid_of([4]f32))
}

// The columns of `#soa[dynamic; N]T` are slices of its `len` elements, made from its inline arrays
@(test)
test_soa_columns_fixed_capacity :: proc(t: ^testing.T) {
	c: #soa[dynamic; 4]P
	append(&c, P{1, 2}, P{3, 4}, P{5, 6})
	ordered_remove(&c, 1)

	testing.expect_value(t, typeid_of(type_of(c.x)), typeid_of([]f32))
	testing.expect_value(t, len(c.x), 2)
	testing.expect_value(t, c.x[1], 5)
	testing.expect_value(t, raw_data(c.y), &c.y[0])

	for &x in c.x {
		x += 10
	}
	testing.expect_value(t, c[0], P{11, 2})
	testing.expect_value(t, c[1], P{15, 6})

	pc := &c
	testing.expect_value(t, len(pc.y), 2)

	testing.expect_value(t, scale_capped(&c, 2), 2)
	testing.expect_value(t, c.y[1], 12)
}
