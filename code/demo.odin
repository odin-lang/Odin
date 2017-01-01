import {
	"atomic.odin";
	"fmt.odin";
	"hash.odin";
	"math.odin";
	"mem.odin";
	"opengl.odin";
	"os.odin";
	"sync.odin";
	"utf8.odin";
	win32 "sys/windows.odin";
}

const Thing = enum f64 {
	_, // Ignore first value
	A = 1<<(10*iota),
	B,
	C,
	D,
};

const main = proc() {
	fmt.println(Thing.A, Thing.B, Thing.C, Thing.D);
}
