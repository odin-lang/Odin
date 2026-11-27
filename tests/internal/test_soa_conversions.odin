package test_internal

import "core:testing"

// Mixed field sizes with no padding, which `==` would compare
@(private="file")
P :: struct {
	x: f32,
	y: u32,
	z: f64,
}

@(private="file")
p :: proc(i: int) -> P {
	return {f32(i), u32(i), f64(-i)}
}

@(private="file", rodata)
g_from_array := (#soa[2]P)([2]P{{1, 2, 3}, {4, 5, 6}})

@(private="file", rodata)
g_from_soa := ([2]P)(#soa[2]P{{1, 2, 3}, {4, 5, 6}})

@(private="file")
sum_x :: proc(s: #soa[4]P) -> (total: f32) {
	for x in s.x {
		total += x
	}
	return
}

// `(#soa[N]T)(a)` and `([N]T)(s)` copy the elements into the other layout
@(test)
test_soa_array_conversions :: proc(t: ^testing.T) {
	a: [4]P
	for &v, i in a {
		v = p(i + 1)
	}

	s := (#soa[4]P)(a)
	testing.expect_value(t, typeid_of(type_of(s)), typeid_of(#soa[4]P))
	for i in 0..<4 {
		testing.expect_value(t, s[i], a[i])
	}
	testing.expect_value(t, s.y[3], 4)

	back := ([4]P)(s)
	testing.expect_value(t, back, a)

	testing.expect_value(t, sum_x((#soa[4]P)(a)), 10)

	// Constants and globals
	c := (#soa[2]P)([2]P{{1, 2, 3}, {4, 5, 6}})
	testing.expect_value(t, c[1], P{4, 5, 6})
	testing.expect_value(t, g_from_array[1], P{4, 5, 6})
	testing.expect_value(t, g_from_soa[0], P{1, 2, 3})

	// Lanes
	l := [3][2]f32{{1, 2}, {3, 4}, {5, 6}}
	ls := (#soa[3][2]f32)(l)
	testing.expect_value(t, ls.y[2], 6)
	testing.expect_value(t, ([3][2]f32)(ls), l)
}

// Long enough for the columns of `#soa[N]T` to be staggered
@(test)
test_soa_array_conversion_staggered :: proc(t: ^testing.T) {
	N :: 1024
	a := new([N]P)
	defer free(a)
	for &v, i in a {
		v = p(i)
	}

	s := new(#soa[N]P)
	defer free(s)
	s^ = (#soa[N]P)(a^)
	for i in ([?]int{0, 1, N/2, N-1}) {
		testing.expect_value(t, s[i], a[i])
	}

	b := new([N]P)
	defer free(b)
	b^ = ([N]P)(s^)
	testing.expect(t, b^ == a^)
}
