package sort

import "core:intrinsics"
import "core:runtime"
import "core:slice"

map_entries_by_key :: proc(m: ^$M/map[$K]$V, loc := #caller_location) where intrinsics.type_is_ordered(K) {
	Entry :: struct {
		hash:  uintptr,
		next:  int,
		key:   K,
		value: V,
	}
	
	header := runtime.__get_map_header(m)
	entries := (^[dynamic]Entry)(&header.m.entries)
	slice.sort_by_key(entries[:], proc(e: Entry) -> K { return e.key })
	runtime.__dynamic_map_reset_entries(header, loc)
}

map_entries_by_value :: proc(m: ^$M/map[$K]$V, loc := #caller_location) where intrinsics.type_is_ordered(V) {
	Entry :: struct {
		hash:  uintptr,
		next:  int,
		key:   K,
		value: V,
	}
	
	header := runtime.__get_map_header(m)
	entries := (^[dynamic]Entry)(&header.m.entries)
	slice.sort_by_key(entries[:], proc(e: Entry) -> V { return e.value })
	runtime.__dynamic_map_reset_entries(header, loc)
}