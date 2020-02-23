package demo

import "core:os"
import "core:sys/win32"

foreign import kernel32 "system:Kernel32.lib"
foreign import user32 "system:User32.lib"

foreign user32 {
	MessageBoxA :: proc "c" (hWnd: rawptr, text, caption: cstring, uType: u32) -> i32 ---
}

foreign kernel32 {
	FlushFileBuffers :: proc "c" (hFile: win32.Handle) -> b32 ---
}



main :: proc() {
	f := os.get_std_handle(win32.STD_OUTPUT_HANDLE);
	os.write_string(f, "Hellope!\n");

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

	// x := i32(1);
	// y := i32(2);
	// z := x + y;
	// w := z - 2;

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
