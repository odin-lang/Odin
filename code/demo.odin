import "fmt.odin";

main :: proc() {
	v, ok := fmt.string_to_enum_value(Allocator.Mode, "FreeAll");
	if ok do assert(v == Allocator.Mode.FreeAll);
}
