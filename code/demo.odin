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

proc main() {
	var x = proc() -> int {
		proc print_here() {
			fmt.println("Here");
		}

		print_here();
		return 1;
	};
	fmt.println(x());
}

