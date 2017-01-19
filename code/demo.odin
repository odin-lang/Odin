#import "atomic.odin";
#import "fmt.odin";
#import "hash.odin";
#import "math.odin";
#import "mem.odin";
#import "opengl.odin";
#import "os.odin";
#import win32 "sys/windows.odin";
#import "sync.odin";
#import "utf8.odin";

main :: proc() {
	// foo :: proc(x: ^i32) -> (int, int) {
	// 	fmt.println("^int");
	// 	return 123, int(x^);
	// }
	// foo :: proc(x: rawptr) {
	// 	fmt.println("rawptr");
	// }

	// THINGI :: 14451;
	// THINGF :: 14451.1;

	// a: i32 = 111111;
	// b: f32;
	// c: rawptr;
	// fmt.println(foo(^a));
	// foo(^b);
	// foo(c);
	// // foo(nil);
	// atomic.store(^a, 1);

	// foo :: proc() {
	// 	fmt.printf("Zero args\n");
	// }
	// foo :: proc(i: int) {
	// 	fmt.printf("int arg, i=%d\n", i);
	// }
	// foo :: proc(f: f64) {
	// 	i := int(f);
	// 	fmt.printf("f64 arg, f=%d\n", i);
	// }

	// foo();
	// // foo(THINGI);
	// foo(THINGF);
	// foo(int(THINGI));
	// fmt.println(THINGI);
	// fmt.println(THINGF);

	// f: proc();
	// f = foo;
	// f();
}
