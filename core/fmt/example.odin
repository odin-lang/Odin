#+build ignore
package custom_formatter_example
import "core:fmt"
import "core:io"

SomeType :: struct {
	value: int,
}

My_Custom_Base_Type :: distinct u32

main :: proc() {
 	// Ensure the fmt._user_formatters map is initialized
	fmt.set_user_formatters(new(map[typeid]fmt.User_Formatter))

	// Register custom formatters for my favorite types
	err := fmt.register_user_formatter(type_info_of(SomeType).id, SomeType_Formatter)
 	assert(err == .None)
	err  = fmt.register_user_formatter(type_info_of(My_Custom_Base_Type).id, My_Custom_Base_Formatter)
 	assert(err == .None)

	// Use the custom formatters.
	fmt.printfln("SomeType{{42}}: '%v'", SomeType{42})
	fmt.printfln("My_Custom_Base_Type(0xdeadbeef): '%v'", My_Custom_Base_Type(0xdeadbeef))
}

SomeType_Formatter :: proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool {
	m := cast(^SomeType)arg.data
	switch verb {
	case 'v', 'd': // We handle `%v` and `%d`
		fmt.fmt_int(fi, u64(m.value), true, 8 * size_of(SomeType), verb)
	case:
		return false
	}
	return true
}

My_Custom_Base_Formatter :: proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool {
	m := cast(^My_Custom_Base_Type)arg.data
	switch verb {
	case 'v', 'b':
		value := u64(m^)
		for value > 0 {
			if value & 1 == 1 {
				io.write_string(fi.writer, "Hellope!", &fi.n)
			} else {
				io.write_string(fi.writer, "Hellope?", &fi.n)
			}
			value >>= 1
		}

	case:
		return false
	}
	return true
}

