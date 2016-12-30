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
	var cond = true;
	var msg = if cond {
		give "hello";
	} else {
		give "goodbye";
	};
	fmt.println(msg);
}
