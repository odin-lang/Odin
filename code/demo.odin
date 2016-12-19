#import "atomic.odin";
#import "fmt.odin";
#import "hash.odin";
#import "math.odin";
#import "mem.odin";
#import "opengl.odin";
#import "os.odin";
#import "sync.odin";
#import "utf8.odin";

type float32 f32;
const (
	X = iota;
	Y;
	Z;
	A = iota+1;
	B;
	C;
);

type Byte_Size f64;
const (
	_            = iota; // ignore first value by assigning to blank identifier
	KB Byte_Size = 1 << (10 * iota);
	MB;
	GB;
	TB;
	PB;
	EB;
);

proc main() {
	fmt.println(X, Y, Z);
	fmt.println(A, B, C);
	fmt.println(KB, MB, GB, TB, PB, EB);
}
