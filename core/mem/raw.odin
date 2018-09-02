package mem

Raw_Any :: struct {
	data: rawptr,
	id:   typeid,
}

Raw_String :: struct {
	data: ^byte,
	len:  int,
}

Raw_Cstring :: struct {
	data: ^byte,
}

Raw_Slice :: struct {
	data: rawptr,
	len:  int,
}

Raw_Dynamic_Array :: struct {
	data:      rawptr,
	len:       int,
	cap:       int,
	allocator: Allocator,
}

Raw_Map :: struct {
	hashes:  []int,
	entries: Raw_Dynamic_Array,
}


make_any :: inline proc(data: rawptr, id: typeid) -> any {
	return transmute(any)Raw_Any{data, id};
}

raw_string_data :: inline proc(s: $T/string) -> ^byte {
	return (^Raw_String)(&s).data;
}
raw_slice_data :: inline proc(a: $T/[]$E) -> ^E {
	return cast(^E)(^Raw_Slice)(&a).data;
}
raw_dynamic_array_data :: inline proc(a: $T/[dynamic]$E) -> ^E {
	return cast(^E)(^Raw_Dynamic_Array)(&a).data;
}

raw_data :: proc[raw_string_data, raw_slice_data, raw_dynamic_array_data];


