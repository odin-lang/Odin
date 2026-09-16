// This file contains pre-defined Handle types. It also contains procedure groups that work with
// both static and dynamic handle maps.
package container_handle_map

// Default 16-bit Handle type which can be used for handle maps which only need a maximum of 254 (1<<8 - 2) items
Handle16 :: struct {
	idx: u8,
	gen: u8,
}

// Default 32-bit Handle type which can be used for handle maps which only need a maximum of 65534 (1<<16 - 2) items
Handle32 :: struct {
	idx: u16,
	gen: u16,
}

// Default 64-bit Handle type which can be used for handle maps which only need a maximum of 4294967294 (1<<32 - 2) items
Handle64 :: struct {
	idx: u32,
	gen: u32,
}

add :: proc{
	static_add,
	dynamic_add,
}

get :: proc{
	static_get,
	dynamic_get,
}

remove :: proc{
	static_remove,
	dynamic_remove,
}

is_valid :: proc{
	static_is_valid,
	dynamic_is_valid,
}

len :: proc{
	static_len,
	dynamic_len,
}

cap :: proc{
	static_cap,
	dynamic_cap,
}

clear :: proc{
	static_clear,
	dynamic_clear,
}

iterator_make :: proc{
	static_iterator_make,
	dynamic_iterator_make,
}

iterate :: proc{
	static_iterate,
	dynamic_iterate,
}
