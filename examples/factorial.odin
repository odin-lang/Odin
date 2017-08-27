import "fmt.odin";

main :: proc() {
	recursive_factorial :: proc(i: u64) -> u64 {
		if i < 2 do return 1;
		return i * recursive_factorial(i-1);
	}

	loop_factorial :: proc(i: u64) -> u64 {
		result: u64 = 1;
		for n in 2..i {
			result *= n;
		}
		return result;
	}


	fmt.println(recursive_factorial(12));
	fmt.println(loop_factorial(12));
}
