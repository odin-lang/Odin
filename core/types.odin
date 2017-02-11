is_signed :: proc(info: ^Type_Info) -> bool {
	if is_integer(info) {
		i := cast(^Type_Info.Integer)info;
		return i.signed;
	}
	if is_float(info) {
		return true;
	}
	return false;
}
is_integer :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }

	match i in type_info_base(info) {
	case Type_Info.Integer: return true;
	}
	return false;
}
is_float :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }

	match i in type_info_base(info) {
	case Type_Info.Float: return true;
	}
	return false;
}
is_any :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }

	match i in type_info_base(info) {
	case Type_Info.Any: return true;
	}
	return false;
}
is_string :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }

	match i in type_info_base(info) {
	case Type_Info.String: return true;
	}
	return false;
}
is_boolean :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }

	match i in type_info_base(info) {
	case Type_Info.Boolean: return true;
	}
	return false;
}
is_pointer :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }

	match i in type_info_base(info) {
	case Type_Info.Pointer: return true;
	}
	return false;
}
is_procedure :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }

	match i in type_info_base(info) {
	case Type_Info.Procedure: return true;
	}
	return false;
}
is_array :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }

	match i in type_info_base(info) {
	case Type_Info.Array: return true;
	}
	return false;
}
is_dynamic_array :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }

	match i in type_info_base(info) {
	case Type_Info.Dynamic_Array: return true;
	}
	return false;
}
is_dynamic_map :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }

	match i in type_info_base(info) {
	case Type_Info.Map: return i.count == 0;
	}
	return false;
}
is_slice :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }

	match i in type_info_base(info) {
	case Type_Info.Slice: return true;
	}
	return false;
}
is_vector :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }

	match i in type_info_base(info) {
	case Type_Info.Vector: return true;
	}
	return false;
}
is_tuple :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }

	match i in type_info_base(info) {
	case Type_Info.Tuple: return true;
	}
	return false;
}
is_struct :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }

	match i in type_info_base(info) {
	case Type_Info.Struct: return true;
	}
	return false;
}
is_union :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }

	match i in type_info_base(info) {
	case Type_Info.Union: return true;
	}
	return false;
}
is_raw_union :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }

	match i in type_info_base(info) {
	case Type_Info.Raw_Union: return true;
	}
	return false;
}
is_enum :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }

	match i in type_info_base(info) {
	case Type_Info.Enum: return true;
	}
	return false;
}
