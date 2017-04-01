#import "fmt.odin";
#import "os.odin";
#import "math.odin";


main :: proc() {
	x := 1+2i;
	y := 3-4i;
	x = x*y;
	fmt.printf("%v\n", x);
}
