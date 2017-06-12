import (
	"fmt.odin";
	"hash.odin";
	"atomics.odin";
	"bits.odin";
	"math.odin";
	"mem.odin";
	"opengl.odin";
	"strconv.odin";
	"strings.odin";
	"sync.odin";
	"types.odin";
	"utf8.odin";
	"utf16.odin";
)

const (
	X = 123;
	Y = 432;
)

proc main() {
	proc(s: string){
		fmt.println(s, "world!");
	}("Hellope");
}
