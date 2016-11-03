x: i64 = 123

Vec2 :: struct {
	x, y: i64
}


main :: proc() {
	foo :: proc() -> i64 {
		bar :: proc() -> (i64, i64) {
			a := [3]i64{7, 4, 2}
			v := Vec2{a[0], 2}
			return v.x, v.y
		}

		x, y := bar()

		return x + y
	}

	test :: proc(s: string) -> string {
		return s
	}

	foo()
	x = test("Hello").count as i64
	xp := ^x
	p := xp^

	z := [..]i64{1, 2, 3, 4}
	z[0] = p
}
