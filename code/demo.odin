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
	var x = ~(0 as u32);
	var y = x << 32;
	fmt.println(y);
}

