type Vec2: struct {
	x, y: f32;
}

print_string_array :: proc(args: []string) {
	args[0] = "";
}

main :: proc() {
	x := 0;

	thing :: proc(n: int) -> int, f32 {
		return n*n, 13.37;
	}

	thang :: proc(a: int, b: f32, s: string) {
	}

	thang(thing(1), "Yep");
}
