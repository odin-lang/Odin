is_signed :: proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	match i in type_info_base(info) {
	case TypeInfo.Integer: return i.signed;
	case TypeInfo.Float:   return true;
	}
	return false;
}
is_integer :: proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^TypeInfo.Integer);
	return ok;
}
is_float :: proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^TypeInfo.Float);
	return ok;
}
is_complex :: proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^TypeInfo.Complex);
	return ok;
}
is_any :: proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^TypeInfo.Any);
	return ok;
}
is_string :: proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^TypeInfo.String);
	return ok;
}
is_boolean :: proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^TypeInfo.Boolean);
	return ok;
}
is_pointer :: proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^TypeInfo.Pointer);
	return ok;
}
is_procedure :: proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^TypeInfo.Procedure);
	return ok;
}
is_array :: proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^TypeInfo.Array);
	return ok;
}
is_dynamic_array :: proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^TypeInfo.DynamicArray);
	return ok;
}
is_dynamic_map :: proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^TypeInfo.Map);
	return ok;
}
is_slice :: proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^TypeInfo.Slice);
	return ok;
}
is_vector :: proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^TypeInfo.Vector);
	return ok;
}
is_tuple :: proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^TypeInfo.Tuple);
	return ok;
}
is_struct :: proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^TypeInfo.Struct);
	return ok;
}
is_union :: proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^TypeInfo.Union);
	return ok;
}
is_raw_union :: proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^TypeInfo.RawUnion);
	return ok;
}
is_enum :: proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^TypeInfo.Enum);
	return ok;
}
