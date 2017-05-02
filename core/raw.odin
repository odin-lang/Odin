Any :: struct {
	data:      rawptr,
	type_info: ^Type_Info,
}

String :: struct {
	data: ^byte,
	len:  int,
};

Slice :: struct {
	data: rawptr,
	len:  int,
	cap:  int,
};

Dynamic_Array :: struct {
	data:      rawptr,
	len:       int,
	cap:       int,
	allocator: Allocator,
};

Dynamic_Map :: struct {
	hashes:  [dynamic]int,
	entries: Dynamic_Array,
};
