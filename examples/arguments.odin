import "core:fmt.odin";
import "core:os.odin";

argc: int;
argv: rawptr;

main :: proc() {
	fmt.println("Arguments: ", os.args);
}
