Any :: struct {
	data:      rawptr,
	type_info: ^Type_Info,
}

String :: struct {
	data: ^byte,
	len:  int,
}

Slice :: struct {
	data: rawptr,
	len:  int,
}

Dynamic_Array :: struct {
	data:      rawptr,
	len:       int,
	cap:       int,
	allocator: Allocator,
}

Map_Internal :: struct {
	hashes:  [dynamic]int,
	entries: Dynamic_Array,
}

Map :: struct {
	using internal: ^Map_Internal,
}

make_any :: inline proc(data: rawptr, type_info: ^Type_Info) -> any {
	return transmute(any)Any{data, type_info};
}

string_data :: inline proc(s: $T/string) -> ^byte {
	return (^String)(&s).data;
}
slice_data :: inline proc(a: $T/[]$E) -> ^E {
	return cast(^E)(^Slice)(&a).data;
}
dynamic_array_data :: inline proc(a: $T/[dynamic]$E) -> ^E {
	return cast(^E)(^Dynamic_Array)(&a).data;
}

data :: proc[string_data, slice_data, dynamic_array_data];
