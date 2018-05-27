package mem

import "core:raw"
import "core:os"


alloc :: inline proc(size: int, alignment: int = DEFAULT_ALIGNMENT, loc := #caller_location) -> rawptr {
	a := context.allocator;
	return a.procedure(a.data, Allocator_Mode.Alloc, size, alignment, nil, 0, 0, loc);
}

free_ptr_with_allocator :: inline proc(a: Allocator, ptr: rawptr, loc := #caller_location) {
	if ptr == nil do return;
	if a.procedure == nil do return;
	a.procedure(a.data, Allocator_Mode.Free, 0, 0, ptr, 0, 0, loc);
}

free_ptr :: inline proc(ptr: rawptr, loc := #caller_location) do free_ptr_with_allocator(context.allocator, ptr);

free_all :: inline proc(loc := #caller_location) {
	a := context.allocator;
	a.procedure(a.data, Allocator_Mode.Free_All, 0, 0, nil, 0, 0, loc);
}


resize :: inline proc(ptr: rawptr, old_size, new_size: int, alignment: int = DEFAULT_ALIGNMENT, loc := #caller_location) -> rawptr {
	a := context.allocator;
	return a.procedure(a.data, Allocator_Mode.Resize, new_size, alignment, ptr, old_size, 0, loc);
}


free_string :: proc(str: string, loc := #caller_location) {
	free_ptr(raw.data(str), loc);
}
free_cstring :: proc(str: cstring, loc := #caller_location) {
	free_ptr((^byte)(str), loc);
}
free_dynamic_array :: proc(array: $T/[dynamic]$E, loc := #caller_location) {
	free_ptr(raw.data(array), loc);
}
free_slice :: proc(array: $T/[]$E, loc := #caller_location) {
	free_ptr(raw.data(array), loc);
}
free_map :: proc(m: $T/map[$K]$V, loc := #caller_location) {
	raw := transmute(raw.Map)m;
	free_dynamic_array(raw.hashes, loc);
	free_ptr(raw.entries.data, loc);
}



default_resize_align :: proc(old_memory: rawptr, old_size, new_size, alignment: int, loc := #caller_location) -> rawptr {
	if old_memory == nil do return alloc(new_size, alignment, loc);

	if new_size == 0 {
		free(old_memory, loc);
		return nil;
	}

	if new_size == old_size do return old_memory;

	new_memory := alloc(new_size, alignment, loc);
	if new_memory == nil do return nil;

	copy(new_memory, old_memory, min(old_size, new_size));;
	free(old_memory, loc);
	return new_memory;
}


default_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                               size, alignment: int,
                               old_memory: rawptr, old_size: int, flags: u64 = 0, loc := #caller_location) -> rawptr {
	using Allocator_Mode;

	switch mode {
	case Alloc:
		return os.heap_alloc(size);

	case Free:
		os.heap_free(old_memory);
		return nil;

	case Free_All:
		// NOTE(bill): Does nothing

	case Resize:
		ptr := os.heap_resize(old_memory, size);
		assert(ptr != nil);
		return ptr;
	}

	return nil;
}

default_allocator :: proc() -> Allocator {
	return Allocator{
		procedure = default_allocator_proc,
		data = nil,
	};
}

nil_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                           size, alignment: int,
                           old_memory: rawptr, old_size: int, flags: u64 = 0, loc := #caller_location) -> rawptr {
	return nil;
}

nil_allocator :: proc() -> Allocator {
	return Allocator{
		procedure = nil_allocator_proc,
		data = nil,
	};
}

