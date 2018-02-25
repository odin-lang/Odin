import "core:fmt.odin"
import "core:strconv.odin"
import "core:mem.odin"
import "core:bits.odin"
import "core:hash.odin"
import "core:math.odin"
import "core:math/rand.odin"
import "core:os.odin"
import "core:raw.odin"
import "core:sort.odin"
import "core:strings.odin"
import "core:types.odin"
import "core:utf16.odin"
import "core:utf8.odin"

// File scope `when` statements
when ODIN_OS == "windows" {
	import "core:atomics.odin"
	import "core:thread.odin"
	import win32 "core:sys/windows.odin"
}

main :: proc() {
	fmt.println("Hellope");

	i := -10;
	x := make([dynamic]int, 0, i);
	fmt.println(x);
}
