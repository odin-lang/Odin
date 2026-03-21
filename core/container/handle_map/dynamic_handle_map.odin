package container_handle_map

import "base:runtime"
import "base:builtin"
import "base:intrinsics"
@(require) import "core:container/xar"

Dynamic_Handle_Map :: struct($T: typeid, $Handle_Type: typeid)
	where
		intrinsics.type_has_field(Handle_Type, "idx"),
		intrinsics.type_has_field(Handle_Type, "gen"),
		intrinsics.type_is_unsigned(intrinsics.type_field_type(Handle_Type, "idx")),
		intrinsics.type_is_unsigned(intrinsics.type_field_type(Handle_Type, "gen")),
		intrinsics.type_field_type(Handle_Type, "idx") == intrinsics.type_field_type(Handle_Type, "gen"),

		intrinsics.type_has_field (T, "handle"),
		intrinsics.type_field_type(T, "handle") == Handle_Type {

	items:        xar.Array(T, 4),
	unused_items: xar.Array(u32, 4),
}

dynamic_init :: proc(m: ^$D/Dynamic_Handle_Map($T, $Handle_Type), allocator: runtime.Allocator) {
	xar.init(&m.items,        allocator)
	xar.init(&m.unused_items, allocator)
}

dynamic_destroy :: proc(m: ^$D/Dynamic_Handle_Map($T, $Handle_Type)) {
	xar.destroy(&m.unused_items)
	xar.destroy(&m.items)
}

@(require_results)
dynamic_add :: proc(m: ^$D/Dynamic_Handle_Map($T, $Handle_Type), item: T, loc := #caller_location) -> (handle: Handle_Type, err: runtime.Allocator_Error) #optional_allocator_error {
	if xar.len(m.unused_items) > 0 {
		i := xar.pop(&m.unused_items)
		ptr := xar.get_ptr_unsafe(&m.items, i)
		prev_gen := ptr.handle.gen
		ptr^ = item

		ptr.handle.idx = auto_cast i
		ptr.handle.gen = auto_cast (prev_gen + 1)
		return ptr.handle, nil
	}

	if xar.len(m.items) == 0 {
		// initialize the zero-value sentinel
		xar.append(&m.items, T{}, loc) or_return
	}

	_ = xar.append(&m.items, item, loc) or_return
	i := xar.len(m.items)-1

	ptr := xar.get_ptr_unsafe(&m.items, i)

	ptr.handle.idx = auto_cast i
	ptr.handle.gen = 1
	return ptr.handle, nil
}

@(require_results)
dynamic_get :: proc "contextless" (m: ^$D/Dynamic_Handle_Map($T, $Handle_Type), h: Handle_Type) -> (^T, bool) #optional_ok {
	if h.idx <= 0 || int(u32(h.idx)) >= xar.len(m.items) {
		return nil, false
	}
	if e := xar.get_ptr_unsafe(&m.items, h.idx); e.handle == h {
		return e, true
	}
	return nil, false
}

dynamic_remove :: proc(m: ^$D/Dynamic_Handle_Map($T, $Handle_Type), h: Handle_Type, loc := #caller_location) -> (found: bool, err: runtime.Allocator_Error) {
	if h.idx <= 0 || int(u32(h.idx)) >= xar.len(m.items) {
		return false, nil
	}

	if item := xar.get_ptr(&m.items, h.idx); item.handle == h {
		xar.append(&m.unused_items, u32(h.idx), loc) or_return
		item.handle.idx = 0
		return true, nil
	}

	return false, nil
}

@(require_results)
dynamic_is_valid :: proc "contextless" (m: ^$D/Dynamic_Handle_Map($T, $Handle_Type), h: Handle_Type) -> bool {
	return h.idx > 0 && int(u32(h.idx)) < xar.len(m.items) && xar.get_ptr_unsafe(&m.items, h.idx).handle == h
}

// Returns the number of possibly valid items in the handle map.
@(require_results)
dynamic_len :: proc "contextless" (m: $D/Dynamic_Handle_Map($T, $Handle_Type)) -> uint {
	n := xar.len(m.items) - xar.len(m.unused_items)
	return uint(n-1 if n > 0 else 0)
}

@(require_results)
dynamic_cap :: proc "contextless" (m: $D/Dynamic_Handle_Map($T, $Handle_Type)) -> uint {
	n := xar.cap(m.items)
	return uint(n-1 if n > 0 else 0)
}

dynamic_clear :: proc "contextless" (m: ^$D/Dynamic_Handle_Map($T, $Handle_Type)) {
	xar.clear(&m.items)
	xar.clear(&m.unused_items)
}


// An iterator for a handle map.
Dynamic_Handle_Map_Iterator :: struct($D: typeid) {
	m:     ^D,
	index: int,
}

// Makes an iterator from a handle map.
@(require_results)
dynamic_iterator_make :: proc "contextless" (m: ^$D/Dynamic_Handle_Map($T, $Handle_Type)) -> Dynamic_Handle_Map_Iterator(D) {
	return {m, 1}
}

/*
	Iterate over a handle map. It will skip over unused item slots (e.g. handle.idx == 0).
	Usage:
		it := hm.dynamic_iterator_make(&the_dynamic_handle_map)
		for item, handle in hm.iterate(&it) {
			...
		}
*/
@(require_results)
dynamic_iterate :: proc "contextless" (it: ^$DHI/Dynamic_Handle_Map_Iterator($D/Dynamic_Handle_Map($T, $Handle_Type))) -> (val: ^T, h: Handle_Type, ok: bool) {
	for _ in it.index..<xar.len(it.m.items) {
		e := xar.get_ptr_unsafe(&it.m.items, it.index)
		it.index += 1

		if e.handle.idx != 0 {
			return e, e.handle, true
		}
	}
	it.index = 0
	return
}