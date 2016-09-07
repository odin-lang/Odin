#load "basic.odin"
#load "math.odin"


print_type_info_kind :: proc(info: ^Type_Info) {
	using Type_Info
	match type i : info {
	case Named:     print_string("Named\n")
	case Integer:   print_string("Integer\n")
	case Float:     print_string("Float\n")
	case String:    print_string("String\n")
	case Boolean:   print_string("Boolean\n")
	case Pointer:   print_string("Pointer\n")
	case Procedure: print_string("Procedure\n")
	case Array:     print_string("Array\n")
	case Slice:     print_string("Slice\n")
	case Vector:    print_string("Vector\n")
	case Struct:    print_string("Struct\n")
	case Union:     print_string("Union\n")
	case Raw_Union: print_string("RawUnion\n")
	case Enum:      print_string("Enum\n")
	default:        print_string("void\n")
	}
}

main :: proc() {
	i: int
	s: struct {
		x, y, z: f32
	}
	p := ^s

	print_type_info_kind(type_info(i))
	print_type_info_kind(type_info(s))
	print_type_info_kind(type_info(p))
}
