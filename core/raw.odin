Any :: struct {
	data:   rawptr,
	typeid: typeid,
}

String :: struct {
	data: ^byte,
	len:  int,
}

Cstring :: struct {
	data: ^byte,
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

Map :: struct {
	hashes:  [dynamic]int,
	entries: Dynamic_Array,
}


make_any :: inline proc(data: rawptr, id: typeid) -> any {
	return transmute(any)Any{data, id};
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


