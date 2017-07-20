import "fmt.odin";
import "strconv.odin";

Opaque :: union{};

main :: proc() {
	buf := make([]u8, 0, 10);
	s := strconv.append_bool(buf, true);
	fmt.println(s);
}

