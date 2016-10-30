x: i64 = 123

Vec2 :: struct {
	x, y: i64
}

main :: proc() {
	bar :: proc() -> i64 {
		a := [3]i64{7, 4, 2}
		v := Vec2{a[0], 2}
		return v.x
	}

	bar()
}
