import (
	"fmt.odin";
)


proc main() {
	var ptr = new(int);
	ptr^ = 123;

	fmt.println(ptr^);
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
