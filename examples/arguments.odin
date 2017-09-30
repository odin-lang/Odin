import "core:fmt.odin";
import "core:os.odin";

main :: proc() {
	fmt.println("Arguments: ", os.args);
}
