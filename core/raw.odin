type Any struct #ordered {
	data:      rawptr,
	type_info: ^TypeInfo,
};

type String struct #ordered {
	data: ^u8,
	len:  int,
};

type Slice struct #ordered {
	data: rawptr,
	len:  int,
	cap:  int,
};

type DynamicArray struct #ordered {
	data:      rawptr,
	len:       int,
	cap:       int,
	allocator: Allocator,
};

type DynamicMap struct #ordered {
	hashes:  [dynamic]int,
	entries: DynamicArray,
};
