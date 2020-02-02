package demo

import "core:os"

main :: proc() {
	Foo :: struct {
		x, y: int,
	};

	x := i32(1);
	y := i32(2);
	z := x + y;
	w := z - 2;


	c := 1 + 2i;
	q := 1 + 2i + 3j + 4k;

	s := "Hellope";

	f: Foo;
	pc: proc "contextless" (x: i32) -> Foo;
	po: proc "odin" (x: i32) -> Foo;
	e: enum{A, B, C};
	u: union{i32, bool};
	u1: union{i32};
	um: union #maybe {^int};

	// os.write_string(os.stdout, "Hellope\n");
}
