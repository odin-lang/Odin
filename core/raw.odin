Any :: struct #ordered {
	data:      rawptr,
	type_info: ^TypeInfo,
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

DynamicArray :: struct #ordered {
	data:      rawptr,
	len:       int,
	cap:       int,
	allocator: Allocator,
};

DynamicMap :: struct #ordered {
	hashes:  [dynamic]int,
	entries: DynamicArray,
};
