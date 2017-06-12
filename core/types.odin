proc is_signed(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	match i in type_info_base(info) {
	case TypeInfo.Integer: return i.signed;
	case TypeInfo.Float:   return true;
	}
	return false;
}
proc is_integer(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Integer);
	return ok;
}
proc is_float(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Float);
	return ok;
}
proc is_complex(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Complex);
	return ok;
}
proc is_any(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Any);
	return ok;
}
proc is_string(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.String);
	return ok;
}
proc is_boolean(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Boolean);
	return ok;
}
proc is_pointer(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Pointer);
	return ok;
}
proc is_procedure(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Procedure);
	return ok;
}
proc is_array(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Array);
	return ok;
}
proc is_dynamic_array(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.DynamicArray);
	return ok;
}
proc is_dynamic_map(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Map);
	return ok;
}
proc is_slice(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Slice);
	return ok;
}
proc is_vector(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Vector);
	return ok;
}
proc is_tuple(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Tuple);
	return ok;
}
proc is_struct(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Struct);
	return ok;
}
proc is_union(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Union);
	return ok;
}
proc is_raw_union(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.RawUnion);
	return ok;
}
proc is_enum(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Enum);
	return ok;
}
