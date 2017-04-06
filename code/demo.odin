#import "atomic.odin";
#import "decimal.odin";
#import "fmt.odin";
#import "hash.odin";
#import "math.odin";
#import "mem.odin";
#import "opengl.odin";
#import "os.odin";
#import "strconv.odin";
#import "strings.odin";
#import "sync.odin";
#import "types.odin";
#import "utf8.odin";
#import "utf16.odin";

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
