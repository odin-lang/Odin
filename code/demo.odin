#import "fmt.odin";

main :: proc() {
	x: atomic int = 123;
	fmt.println(x);
	arr :[dynamic]any;
	append(arr, "123", 123, 3.14159265359878, true);
	for a in arr {
		fmt.println(a);
	}
	fmt.print(arr, "\n");
}
