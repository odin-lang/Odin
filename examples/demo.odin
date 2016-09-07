#load "basic.odin"
#load "math.odin"


print_type_info_kind :: proc(info: ^Type_Info) {
	using Type_Info
	match type info -> i {
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

println :: proc(args: ..any) {
	for i := 0; i < len(args); i++ {
		arg := args[i]

		if i > 0 {
			print_string(" ")
		}

		using Type_Info
		match type arg.type_info -> i {
		case Named:     print_string("Named")
		case Integer:   print_string("Integer")
		case Float:     print_string("Float")
		case String:    print_string("String")
		case Boolean:   print_string("Boolean")
		case Pointer:   print_string("Pointer")
		case Procedure: print_string("Procedure")
		case Array:     print_string("Array")
		case Slice:     print_string("Slice")
		case Vector:    print_string("Vector")
		case Struct:    print_string("Struct")
		case Union:     print_string("Union")
		case Raw_Union: print_string("RawUnion")
		case Enum:      print_string("Enum")
		default:        print_string("void")
		}
	}

	print_nl()
}

main :: proc() {
	i: int
	s: struct {
		x, y, z: f32
	}
	p := ^s

	a: any = i

	println(137, "Hello", 1.23)

	// print_type_info_kind(a.type_info)
	// print_type_info_kind(type_info(s))
	// print_type_info_kind(type_info(p))
}
