package demo

import "core:os"

// Foo :: struct {
// 	x, y: int,
// };
// foo :: proc(x: int) -> (f: Foo) {
// 	return;
// }

main :: proc() {
	Foo :: enum {A=1, B, C, D};
	Foo_Set :: bit_set[Foo];
	x := Foo_Set{.A, .C};

	y := [4]int{3 = 1, 0 .. 1 = 3, 2 = 9};
	z := []int{1, 2, 3, 4};

	// @thread_local a: int;

	// x := i32(1);
	// y := i32(2);
	// z := x + y;
	// w := z - 2;

	// foo(123);


	// c := 1 + 2i;
	// q := 1 + 2i + 3j + 4k;

	// s := "Hellope";

	// f := Foo{1, 2};
	// pc: proc "contextless" (x: i32) -> Foo;
	// po: proc "odin" (x: i32) -> Foo;
	// e: enum{A, B, C};
	// u: union{i32, bool};
	// u1: union{i32};
	// um: union #maybe {^int};

	// os.write_string(os.stdout, "Hellope\n");
	return;
}
