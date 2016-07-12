main :: proc() {
	x := "Yep";

	thing :: proc(n: int) -> (int, f32) {
		return n*n, 13.37;
	}

	thang(thing(1), x);

	v: Vec2;
}

thang :: proc(a: int, b: f32, s: string) {
	a = 1;
	b = 2;
	s = "Hello";
}

z := y;
y := x;
x := 1;

type Vec2: struct {
	x, y: f32;
}

