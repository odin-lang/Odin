main :: proc() {
	x : u8 = 0;

	thing :: proc(n: int) -> (int, f32) {
		return n*n, 13.37;
	}

	thang :: proc(a: int, b: f32, s: string) {
	}

	thang(thing(1), "Yep");
}
