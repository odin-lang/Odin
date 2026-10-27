package pkg_a

@(require) import str "core:strings"

@(priority_index=2)
foreign import tool_lib "system:tool_lib"

foreign tool_lib {
	tool_value :: proc "c" () -> i32 ---
}

Point :: struct {
	x: f32,
	y: f32,
	z: i64,
}

FIVE :: 5

@(require_results)
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

Axis :: enum {X, Y}
Side :: enum {X, Left}

Nibbles :: bit_field u8 {
	lo: u8 | 4,
	hi: u8 | 4,
}

axis :: proc(a: Axis, i: int) -> int {
	return int(a) + i
}

side :: proc(s: Side, f: f32) -> int {
	return int(s) + int(f)
}

pick :: proc{axis, side}

use_all :: proc() -> int {
	@(static) calls: int
	calls += 1
	p := Point{1, 2, 3}
	a := twice(int(p.z))
	b := twice(p.x)
	c := add(a, FIVE) + int(b) + pick(.X, 1) + add_int(b = 1, a = 2) + int(offset_of(Point, y))
	if str.contains("ab", "a") {
		c += 1
	}
	when FIVE == 6 {
		c += 100
	} else {
		c += REPLACED + ADDED
	}
	return c
}

@(private="file", require_results)
@(deprecated="use add_int")
plus :: proc(a, b: int) -> int {
	return a + b
}
