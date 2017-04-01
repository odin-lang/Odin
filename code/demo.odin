#import "fmt.odin";
#import "os.odin";
#import "math.odin";


main :: proc() {
	x := 1+2i+3j+4k;
	y := 3-4i-5j-6k;
	z := x/y;
	fmt.println(z, abs(z));
}
