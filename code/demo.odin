#import "fmt.odin";

main :: proc() {
	foo :: proc() -> [dynamic]int {
		x: [dynamic]int;
		append(^x, 2, 3, 5, 7);
		return x;
	}

	for p in foo() {
		fmt.println(p);
	}
}
