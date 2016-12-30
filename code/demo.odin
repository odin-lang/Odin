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

proc main() {
	var x = if false {
		give 123;
	} else {
		give 321;
	};
	fmt.println(x);
}
