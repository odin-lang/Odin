#import "fmt.odin";
#import "os.odin";

main :: proc() {
	immutable program := "+ + * - /";
	accumulator := 0;

	for token in program {
		match token {
		case '+': accumulator += 1;
		case '-': accumulator -= 1;
		case '*': accumulator *= 2;
		case '/': accumulator /= 2;
		default: // Ignore everything else
		}
	}

	fmt.printf("The program \"%s\" calculates the value %d\n", program, accumulator);
}
