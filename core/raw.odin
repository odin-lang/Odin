Any :: struct #ordered {
	data:      rawptr,
	type_info: ^Type_Info,
}

String :: struct #ordered {
	data: ^byte,
	len:  int,
}

Slice :: struct #ordered {
	data: rawptr,
	len:  int,
}

Dynamic_Array :: struct #ordered {
	data:      rawptr,
	len:       int,
	cap:       int,
	allocator: Allocator,
}

Map :: struct #ordered {
	hashes:  [dynamic]int,
	entries: Dynamic_Array,
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
