is_signed :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	match i in type_info_base(info).variant {
	case TypeInfo.Integer: return i.signed;
	case TypeInfo.Float:   return true;
	}
	return false;
}
is_integer :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(TypeInfo.Integer);
	return ok;
}
is_rune :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(TypeInfo.Rune);
	return ok;
}
is_float :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(TypeInfo.Float);
	return ok;
}
is_complex :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(TypeInfo.Complex);
	return ok;
}
is_any :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(TypeInfo.Any);
	return ok;
}
is_string :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(TypeInfo.String);
	return ok;
}
is_boolean :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(TypeInfo.Boolean);
	return ok;
}
is_pointer :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(TypeInfo.Pointer);
	return ok;
}
is_procedure :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(TypeInfo.Procedure);
	return ok;
}
is_array :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(TypeInfo.Array);
	return ok;
}
is_dynamic_array :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(TypeInfo.DynamicArray);
	return ok;
}
is_dynamic_map :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(TypeInfo.Map);
	return ok;
}
is_slice :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(TypeInfo.Slice);
	return ok;
}
is_vector :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(TypeInfo.Vector);
	return ok;
}
is_tuple :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(TypeInfo.Tuple);
	return ok;
}
is_struct :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(TypeInfo.Struct);
	return ok;
}
is_union :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(TypeInfo.Union);
	return ok;
}
is_raw_union :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(TypeInfo.RawUnion);
	return ok;
}
is_enum :: proc(info: ^TypeInfo) -> bool {
	if info == nil do return false;
	_, ok := type_info_base(info).variant.(TypeInfo.Enum);
	return ok;
}
