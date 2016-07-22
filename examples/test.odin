// import "other"

TAU :: 6.28;
PI :: PI/2;

type AddProc: proc(a, b: int) -> int;


do_thing :: proc(p: AddProc) {
	p(1, 2);
}

add :: proc(a, b: int) -> int {
	return a + b;
}


main :: proc() {
	x : int = 2;
	x = x * 3;

	// do_thing(add(1, x));
	do_thing(proc(a, b: int) -> f32 {
		return a*b - a%b;
	});

}
