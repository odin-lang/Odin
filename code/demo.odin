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

type Thing enum f64 {
	_, // Ignore first value
	A = 1<<(10*iota),
	B,
	C,
	D,
}

proc main() {
	var ti = type_info(Thing);
	match type info : type_info_base(ti) {
	case Type_Info.Enum:
		for var i = 0; i < info.names.count; i++ {
			if i > 0 {
				fmt.print(", ");
			}
			fmt.print(info.names[i]);
		}
		fmt.println();
	}

	fmt.println(Thing.A, Thing.B, Thing.C, Thing.D);

}
