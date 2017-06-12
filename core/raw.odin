const Any = struct #ordered {
	data:      rawptr,
	type_info: ^TypeInfo,
}

const String = struct #ordered {
	data: ^u8,
	len:  int,
};

const Slice = struct #ordered {
	data: rawptr,
	len:  int,
	cap:  int,
};

const DynamicArray = struct #ordered {
	data:      rawptr,
	len:       int,
	cap:       int,
	allocator: Allocator,
};

const DynamicMap = struct #ordered {
	hashes:  [dynamic]int,
	entries: DynamicArray,
};
