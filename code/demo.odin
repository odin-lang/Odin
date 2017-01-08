#import "fmt.odin";

main :: proc() {
	using Type_Info;
	is_type_integer :: proc(info: ^Type_Info) -> bool {
		if info == nil {
			return false;
		}

		match type i : type_info_base(info) {
		case Integer:
			return true;
		}
		return false;
	}

	ti := type_info_base(type_info(Allocator_Mode));
	match type e : ti {
	case Enum:
		is_int := is_type_integer(e.base);
		for i : 0..<e.names.count {
			name  := e.names[i];
			value := e.values[i];
			if is_int {
				fmt.printf("%s - %d\n", name, value.i);
			} else {
				fmt.printf("%s - %f\n", name, value.f);
			}
		}
	}
}
