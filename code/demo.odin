#import "fmt.odin";

main :: proc() {
	x: [dynamic]f64;
	defer free(x);
	append(^x, 2_000_000.500_000, 3, 5, 7);

	for p, i in x {
		if i > 0 { fmt.print(", "); }
		fmt.print(p);
	}
	fmt.println();
}
