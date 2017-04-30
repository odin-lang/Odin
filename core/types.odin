is_signed :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	match i in type_info_base(info) {
	case Type_Info.Integer: return i.signed;
	case Type_Info.Float:   return true;
	}
	return false;
}
is_integer :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^Type_Info.Integer);
	return ok;
}
is_float :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^Type_Info.Float);
	return ok;
}
is_complex :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^Type_Info.Complex);
	return ok;
}
is_any :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^Type_Info.Any);
	return ok;
}
is_string :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^Type_Info.String);
	return ok;
}
is_boolean :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^Type_Info.Boolean);
	return ok;
}
is_pointer :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^Type_Info.Pointer);
	return ok;
}
is_procedure :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^Type_Info.Procedure);
	return ok;
}
is_array :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^Type_Info.Array);
	return ok;
}
is_dynamic_array :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^Type_Info.Dynamic_Array);
	return ok;
}
is_dynamic_map :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^Type_Info.Map);
	return ok;
}
is_slice :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^Type_Info.Slice);
	return ok;
}
is_vector :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^Type_Info.Vector);
	return ok;
}
is_tuple :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^Type_Info.Tuple);
	return ok;
}
is_struct :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^Type_Info.Struct);
	return ok;
}
is_union :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^Type_Info.Union);
	return ok;
}
is_raw_union :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^Type_Info.Raw_Union);
	return ok;
}
is_enum :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := type_info_base(info).(^Type_Info.Enum);
	return ok;
}
