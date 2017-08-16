Any :: struct #ordered {
	data:      rawptr;
	type_info: ^Type_Info;
};

String :: struct #ordered {
	data: ^u8;
	len:  int;
};

Slice :: struct #ordered {
	data: rawptr;
	len:  int;
	cap:  int;
};

Dynamic_Array :: struct #ordered {
	data:      rawptr;
	len:       int;
	cap:       int;
	allocator: Allocator;
};

Map :: struct #ordered {
	hashes:  [dynamic]int;
	entries: Dynamic_Array;
};

