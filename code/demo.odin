import (
	"fmt.odin";
)

proc new_type(T: type) -> ^T {
	return ^T(alloc_align(size_of(T), align_of(T)));
}

proc main() {
	var ptr = new_type(int);
}

/*
	let program = "+ + * - /";
	var accumulator = 0;

	for token in program {
		match token {
		case '+': accumulator += 1;
		case '-': accumulator -= 1;
		case '*': accumulator *= 2;
		case '/': accumulator /= 2;
		case: // Ignore everything else
		}
	}

	fmt.printf("The program \"%s\" calculates the value %d\n",
	           program, accumulator);
*/
}
