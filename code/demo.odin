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
	var a, b, c = {
		give 1, 2, 123*321;
	};
	fmt.println(a, b, c);
}
