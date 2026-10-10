package pkg_a

Point :: struct {
	x: f32,
	y: f32,
	z: i64,
}

FIVE :: 5

twice :: proc(x: $T) -> T {
	return x + x
}

add_int :: proc(a, b: int) -> int {
	return a + b
}

add_f32 :: proc(a, b: f32) -> f32 {
	return a + b
}

add :: proc{add_int, add_f32}

use_all :: proc() -> int {
	p := Point{1, 2, 3}
	a := twice(int(p.z))
	b := twice(p.x)
	c := add(a, FIVE) + int(b)
	when FIVE == 6 {
		c += 100
	} else {
		c += REPLACED + ADDED
	}
	return c
}
