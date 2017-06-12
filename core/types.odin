const is_signed = proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	match i in type_info_base(info) {
	case TypeInfo.Integer: return i.signed;
	case TypeInfo.Float:   return true;
	}
	return false;
}
const is_integer = proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Integer);
	return ok;
}
const is_float = proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Float);
	return ok;
}
const is_complex = proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Complex);
	return ok;
}
const is_any = proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Any);
	return ok;
}
const is_string = proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.String);
	return ok;
}
const is_boolean = proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Boolean);
	return ok;
}
const is_pointer = proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Pointer);
	return ok;
}
const is_procedure = proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Procedure);
	return ok;
}
const is_array = proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Array);
	return ok;
}
const is_dynamic_array = proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.DynamicArray);
	return ok;
}
const is_dynamic_map = proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Map);
	return ok;
}
const is_slice = proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Slice);
	return ok;
}
const is_vector = proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Vector);
	return ok;
}
const is_tuple = proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Tuple);
	return ok;
}
const is_struct = proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Struct);
	return ok;
}
const is_union = proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Union);
	return ok;
}
const is_raw_union = proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.RawUnion);
	return ok;
}
const is_enum = proc(info: ^TypeInfo) -> bool {
	if info == nil { return false; }
	var _, ok = type_info_base(info).(^TypeInfo.Enum);
	return ok;
}
