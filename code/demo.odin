import (
	"atomic.odin";
	"fmt.odin";
	"hash.odin";
	"math.odin";
	"mem.odin";
	"opengl.odin";
	"os.odin";
	"sync.odin";
	"utf8.odin";
)

type Byte_Size f64;
const (
	_            = iota; // ignore first value by assigning to blank identifier
	KB Byte_Size = 1 << (10 * iota);
	// Because there is no type or expression, the previous one is used but
	// with `iota` incremented by one
	MB;
	GB;
	TB;
	PB;
	EB;
)


proc main() {
	fmt.println("Here");

}

