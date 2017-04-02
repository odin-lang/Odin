is_signed :: proc(info: ^Type_Info) -> bool {
	info = type_info_base(info);
	if i, ok := union_cast(^Type_Info.Integer)info; ok {
		return i.signed;
	}
	if _, ok := union_cast(^Type_Info.Float)info; ok {
		return true;
	}
	return false;
}
is_integer :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := union_cast(^Type_Info.Integer)type_info_base(info);
	return ok;
}
is_float :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := union_cast(^Type_Info.Float)type_info_base(info);
	return ok;
}
is_complex :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := union_cast(^Type_Info.Complex)type_info_base(info);
	return ok;
}
is_any :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := union_cast(^Type_Info.Any)type_info_base(info);
	return ok;
}
is_string :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := union_cast(^Type_Info.String)type_info_base(info);
	return ok;
}
is_boolean :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := union_cast(^Type_Info.Boolean)type_info_base(info);
	return ok;
}
is_pointer :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := union_cast(^Type_Info.Pointer)type_info_base(info);
	return ok;
}
is_procedure :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := union_cast(^Type_Info.Procedure)type_info_base(info);
	return ok;
}
is_array :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := union_cast(^Type_Info.Array)type_info_base(info);
	return ok;
}
is_dynamic_array :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := union_cast(^Type_Info.Dynamic_Array)type_info_base(info);
	return ok;
}
is_dynamic_map :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := union_cast(^Type_Info.Map)type_info_base(info);
	return ok;
}
is_slice :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := union_cast(^Type_Info.Slice)type_info_base(info);
	return ok;
}
is_vector :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := union_cast(^Type_Info.Vector)type_info_base(info);
	return ok;
}
is_tuple :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := union_cast(^Type_Info.Tuple)type_info_base(info);
	return ok;
}
is_struct :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := union_cast(^Type_Info.Struct)type_info_base(info);
	return ok;
}
is_union :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := union_cast(^Type_Info.Union)type_info_base(info);
	return ok;
}
is_raw_union :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := union_cast(^Type_Info.Raw_Union)type_info_base(info);
	return ok;
}
is_enum :: proc(info: ^Type_Info) -> bool {
	if info == nil { return false; }
	_, ok := union_cast(^Type_Info.Enum)type_info_base(info);
	return ok;
}
