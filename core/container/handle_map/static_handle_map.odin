package container_handle_map

import "base:builtin"
import "base:intrinsics"

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

Static_Handle_Map :: struct($N: uint, $T: typeid, $Handle_Type: typeid)
	where
		0 < N, N < uint(1<<31 - 1),

		intrinsics.type_has_field(Handle_Type, "idx"),
		intrinsics.type_has_field(Handle_Type, "gen"),
		intrinsics.type_is_unsigned(intrinsics.type_field_type(Handle_Type, "idx")),
		intrinsics.type_is_unsigned(intrinsics.type_field_type(Handle_Type, "gen")),
		intrinsics.type_field_type(Handle_Type, "idx") == intrinsics.type_field_type(Handle_Type, "gen"),

		N < uint(max(intrinsics.type_field_type(Handle_Type, "idx"))),

		intrinsics.type_has_field (T, "handle"),
		intrinsics.type_field_type(T, "handle") == Handle_Type {

	// The zero element represent a zero-value sentinel (dummy value), allowing for `idx == 0` to mean a no-handle.
	// This means the capacity is actually N-1 items.
	items: [N]T,

	used_len:     u32, // How many of the items are in use
	unused_len:   u32, // Use to calculate the number of valid items
	unused_items: [N]u32,
	next_unused:  u32,
}


// `add` a value of type `T` to the handle map. This will return a pointer to the item and an optional boolean to check for validity.
@(require_results)
static_add :: proc "contextless" (m: ^$H/Static_Handle_Map($N, $T, $Handle_Type), item: T) -> (handle: Handle_Type, ok: bool) #optional_ok {
	if i := m.next_unused; i != 0 {
		ptr := &m.items[i]

		m.next_unused = m.unused_items[i]
		m.unused_items[i] = 0

		prev_gen := ptr.handle.gen
		ptr^ = item

		ptr.handle.idx = auto_cast i
		ptr.handle.gen = auto_cast (prev_gen + 1)
		m.unused_len -= 1
		return ptr.handle, true
	}

	if m.used_len == 0 {
		// initialize the zero-value sentinel
		m.items[0] = {}
		m.used_len += 1
	}

	if m.used_len == builtin.len(m.items) {
		return {}, false
	}

	ptr := &m.items[m.used_len]
	ptr^ = item

	ptr.handle.idx = auto_cast m.used_len
	ptr.handle.gen = 1
	m.used_len += 1
	return ptr.handle, true
}

// `get` a stable pointer of type `^T` by resolving the handle `h`. If the handle is not valid, then `nil, false` is returned.
@(require_results)
static_get :: proc "contextless" (m: ^$H/Static_Handle_Map($N, $T, $Handle_Type), h: Handle_Type) -> (^T, bool) #optional_ok {
	if h.idx <= 0 || u32(h.idx) >= m.used_len {
		return nil, false
	}
	if e := &m.items[h.idx]; e.handle == h {
		return e, true
	}
	return nil, false
}

// `remove` an item from the handle map from the handle `h`.
static_remove :: proc "contextless" (m: ^$H/Static_Handle_Map($N, $T, $Handle_Type), h: Handle_Type) -> bool {
	if h.idx <= 0 || u32(h.idx) >= m.used_len {
		return false
	}

	if item := &m.items[h.idx]; item.handle == h {
		m.unused_items[h.idx] = m.next_unused
		m.next_unused = u32(h.idx)
		m.unused_len += 1
		item.handle.idx = 0
		return true
	}

	return false
}

// Returns true when the handle `h` is valid relating to the handle map.
@(require_results)
static_is_valid :: proc "contextless" (m: $H/Static_Handle_Map($N, $T, $Handle_Type), h: Handle_Type) -> bool {
	return h.idx > 0 && u32(h.idx) < m.used_len && m.items[h.idx].handle == h
}

// Returns the number of possibly valid items in the handle map.
@(require_results)
static_len :: proc "contextless" (m: $H/Static_Handle_Map($N, $T, $Handle_Type)) -> uint {
	n := uint(m.used_len) - uint(m.unused_len)
	return n-1 if n > 0 else 0
}

// Returns the capacity of the items in a handle map.
// This is equivalent to `N-1` as the zero value is reserved for the zero-value sentinel.
@(require_results)
static_cap :: proc "contextless" (m: $H/Static_Handle_Map($N, $T, $Handle_Type)) -> uint {
	// We could just return `N` but I am doing this for clarity
	return builtin.len(m.items)-1
}

// `clear` the handle map by zeroing all of the memory.
// Internally this does not do `m^ = {}` but rather uses `intrinsics.mem_zero` explicitly improve performance.
static_clear :: proc "contextless" (m: ^$H/Static_Handle_Map($N, $T, $Handle_Type)) {
	intrinsics.mem_zero(m, size_of(m^))
}

// An iterator for a handle map.
Static_Handle_Map_Iterator :: struct($H: typeid) {
	m:     ^H,
	index: u32,
}

// Makes an iterator from a handle map.
@(require_results)
static_iterator_make :: proc "contextless" (m: ^$H/Static_Handle_Map($N, $T, $Handle_Type)) -> Static_Handle_Map_Iterator(H) {
	return {m, 1}
}

/*
	Iterate over a handle map. It will skip over unused item slots (e.g. handle.idx == 0).
	Usage:
		it := hm.iterator_make(&the_handle_map)
		for item, handle in hm.iterate(&it) {
			...
		}
*/
@(require_results)
static_iterate :: proc "contextless" (it: ^$HI/Static_Handle_Map_Iterator($H/Static_Handle_Map($N, $T, $Handle_Type))) -> (val: ^T, h: Handle_Type, ok: bool) {
	for _ in it.index..<it.m.used_len {
		e := &it.m.items[it.index]
		it.index += 1

		if e.handle.idx != 0 {
			return e, e.handle, true
		}
	}
	it.index = 0
	return
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
