#import "fmt.odin";

main :: proc() {
	foo :: proc() {
		fmt.printf("Zero args\n");
	}
	foo :: proc(i: int) {
		fmt.printf("One arg, i=%d\n", i);
	}
	THING :: 14451;

	foo();
	foo(THING);
	fmt.println(THING);

	x: proc();
	x = foo;
	x();
}
