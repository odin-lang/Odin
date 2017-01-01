import "atomic.odin";
import "fmt.odin";
import "hash.odin";
import "math.odin";
import "mem.odin";
import "opengl.odin";
import "os.odin";
import "sync.odin";
import "utf8.odin";
import win32 "sys/windows.odin";

Thing :: enum f64 {
	_, // Ignore first value
	A = 1<<(10*iota),
	B,
	C,
	D,
};

main :: proc() {
	fmt.println(Thing.A, Thing.B, Thing.C, Thing.D);

	x := 123;
	fmt.println(x);
}
