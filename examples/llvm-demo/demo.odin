package demo

import "core:os"
import "core:fmt"

main :: proc() {
	fmt.fprintln(os.stdout, "Hellope!", 123, true, 1.3);
}

	// BarBar :: struct {x, y: int};

	// foo :: proc(x: int) {}

	// Foo :: enum {A=1, B, C, D};
	// Foo_Set :: bit_set[Foo];
	// foo_set := Foo_Set{.A, .C};

	// array := [4]int{3 = 1, 0 .. 1 = 3, 2 = 9};
	// slice := []int{1, 2, 3, 4};

	// x: ^int = nil;
	// y := slice != nil;

	// @thread_local a: int;

	// if true {
	// 	foo(1);
	// }

	// {
	// 	x := i32(1);
	// 	y := i32(2);
	// 	z := x + y;
	// 	w := z - 2;
	// }

	// f := foo;

	// c := 1 + 2i;
	// q := 1 + 2i + 3j + 4k;

	// s := "Hellope";

	// b := true;
	// aaa := b ? int(123) : int(34);
	// defer aaa = 333;

	// bb := BarBar{1, 2};
	// pc: proc "contextless" (x: i32) -> BarBar;
	// po: proc "odin" (x: i32) -> BarBar;
	// e: enum{A, B, C};
	// u: union{i32, bool};
	// u1: union{i32};
	// um: union #maybe {^int};
}
