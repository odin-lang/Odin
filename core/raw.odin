Any :: struct #ordered {
	type_info: ^Type_Info,
	data:      rawptr,
}

String :: struct #ordered {
	data: ^byte,
	len:  int,
};

Slice :: struct #ordered {
	data: rawptr,
	len:  int,
	cap:  int,
};

Dynamic_Array :: struct #ordered {
	data:      rawptr,
	len:       int,
	cap:       int,
	allocator: Allocator,
};

Dynamic_Map :: struct #ordered {
	hashes:  [dynamic]int,
	entries: Dynamic_Array,
};
