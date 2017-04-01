#import "fmt.odin";
#import "os.odin";
#import "math.odin";

main :: proc() {
	x := 1+2i+3j+4k;
	y := conj(x);
	z := x/y;
	fmt.println(z, abs(z));
}
