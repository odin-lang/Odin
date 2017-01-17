#import "atomic.odin";
#import "fmt.odin";
#import "math.odin";
#import "mem.odin";

main :: proc() {
	foo :: proc(x: ^int) {
		fmt.println("^int");
	}
	foo :: proc(x: rawptr) {
		fmt.println("rawptr");
	}

	a: ^int;
	b: ^f32;
	c: rawptr;
	foo(a);
	foo(b);
	foo(c);
	// foo(nil);

	foo :: proc() {
		fmt.printf("Zero args\n");
	}
	foo :: proc(i: int) {
		fmt.printf("int arg, i=%d\n", i);
	}
	foo :: proc(f: f64) {
		i := f as int;
		fmt.printf("f64 arg, f=%d\n", i);
	}
	THINGI :: 14451;
	THINGF :: 14451.1;


	foo();
	foo(THINGI as int);
	foo(int(THINGI));
	// foo(THINGI);
	foo(THINGF);
	fmt.println(THINGI);
	fmt.println(THINGF);

	f: proc();
	f = foo;
	f();
}
