package virtual

import "core:mem"
import "core:os"

// Returns a pointer to the first byte of the page the given pointer is in.
enclosing_page :: proc(ptr: rawptr) -> rawptr {
	page_size := os.get_page_size();
	start := mem.align_backward(ptr, uintptr(page_size));
	return start;
}

// Returns a pointer to the first byte of the page after the one the given pointer is in.
next_page :: proc(ptr: rawptr) -> rawptr {
	page_size := os.get_page_size();
	start := mem.align_forward(rawptr(uintptr(ptr)+1), uintptr(page_size));
	return start;
}

// Returns a pointer to the first byte of the page before the one the given pointer is in.
previous_page :: proc(ptr: rawptr) -> rawptr {
	page_size := os.get_page_size();
	start := mem.align_backward(rawptr(uintptr(ptr)-1), uintptr(page_size));
	return start;
}

// Given a number of bytes, returns the number of pages needed to contain it.
bytes_to_pages :: proc(size: int) -> int {
	page_size := os.get_page_size();
	bytes := mem.align_forward_uintptr(uintptr(size), uintptr(page_size));
	return int(bytes) / page_size;
}


// A push buffer, just like `mem.Arena`, but which is backed by virtual memory.
//
// This means that you can have a multiple-gigabyte contiguous block of memory,
// but only have the amount you actually use committed to physical memory.
//
// Resetting this arena will decommit the memory out of physical memory, and will
// therefore free up system resources.
//
// WARNING: attempting to write to a pointer within this arena that was returned by
// `arena_alloc` after `arena_free_all` has been called, will segfault.
// Attempting to modify data in the arena's buffer before it has been returned from `arena_alloc` may also segfault.
Arena :: struct {
	base:            rawptr,
	max_size:        int,
	cursor:          rawptr, // next location that's valid to return to the user
	pages_committed: int,
	high_mark:       int, // largest number of bytes allocated

	desired_base_ptr: rawptr, // may be nil on first allocation
}

// Initialize an area with the given maximum size and base pointer.
// The max size can be abnormally huge, since only what you write to will be committed to physical memory.
arena_init :: proc(va: ^Arena, max_size: int, desired_base_ptr: rawptr = nil) {
	va.max_size = max_size;
	va.base = nil;
	va.cursor = nil;
	va.desired_base_ptr = desired_base_ptr;
}

arena_free_all :: proc(using va: ^Arena) {
	cursor = base;
	decommit(mem.slice_ptr(cast(^byte) base, max_size));
}

arena_alloc :: proc(va: ^Arena, requested_size, alignment: int) -> rawptr {
	if va.base == nil {
		if va.max_size == 0 do return nil; // NOTE(tetra): Size specified as zero, or arena not initialized

		// NOTE(tetra): Initialize the base ptr if we haven't yet; this is how we avoid reserving any memory
		// unless any is actually requested.
		// It's also how we only reserve the first time we're asked to allocate.

		base_ptr := reserve(va.max_size, va.desired_base_ptr);
		if base_ptr == nil do return nil;

		va.base = &base_ptr[0];
		va.cursor = va.base;
	}


	// NOTE(tetra): Check the new region stays with the arena, commit the pages,
	// and shift up the cursor.

	region     := cast(^byte) mem.align_forward(va.cursor, uintptr(alignment));
	region_end := mem.ptr_offset(region, requested_size);
	base       := cast(^byte) va.base;
	arena_end  := mem.ptr_offset(base, va.max_size);
	if region_end > arena_end {
		return nil;
	}

	total_pages_needed := bytes_to_pages(mem.ptr_sub(region_end, base));
	if total_pages_needed > va.pages_committed {
		ok := commit(mem.slice_ptr(base, max(total_pages_needed, 1) * os.get_page_size()));
		assert(ok);
		va.pages_committed = total_pages_needed;
	}

	va.high_mark = max(va.high_mark, mem.ptr_sub(region_end, base));
	va.cursor = region_end;
	return region;
}

// You may resize the last allocation requested using this procedure, in which case, no data will be copied.
arena_realloc :: proc(va: ^Arena, old_memory: rawptr, old_size, size, alignment: int) -> rawptr {
	old_region_end := mem.ptr_offset(cast(^byte)old_memory, old_size);

	// NOTE(tetra): If we can't resize in place, copy to new allocation instead.
	if old_memory == nil || old_region_end != va.cursor {
		ptr := arena_alloc(va, size, alignment);
		if ptr == nil do return nil;

		mem.copy(ptr, old_memory, old_size);
		return ptr;
	}


	// NOTE(tetra): We were the last allocation; commit the new pages and shift up the cursor.

	new_region_end := mem.ptr_offset(cast(^byte)old_memory, size);
	base           := cast(^byte) va.base;
	arena_end      := mem.ptr_offset(base, va.max_size);
	if new_region_end > arena_end {
		return nil;
	}

	total_pages_needed := bytes_to_pages(mem.ptr_sub(new_region_end, base));
	if total_pages_needed > va.pages_committed {
		ok := commit(mem.slice_ptr(base, max(total_pages_needed, 1) * os.get_page_size()));
		assert(ok);
		va.pages_committed = total_pages_needed;
	}

	va.cursor = new_region_end;
	va.high_mark = max(va.high_mark, mem.ptr_sub(new_region_end, base));
	return old_memory;
}

// Releases the virtual memory back to the system.
// Afterwards, the arena can be initialized again with `arena_init`.
arena_destroy :: proc(using va: ^Arena) {
	free(mem.slice_ptr(cast(^byte) base, max_size));
	va^ = {};
}

arena_allocator_proc :: proc(data: rawptr, mode: mem.Allocator_Mode,
                             size, alignment: int,
						     old_memory: rawptr, old_size: int,
						     flags: u64 = 0, loc := #caller_location) -> rawptr {
	arena := cast(^Arena) data;

	if old_memory != nil && !(arena.base <= old_memory && old_memory <= arena.cursor) do
		panic("memory does not belong to this allocator", loc);

	switch mode {
	case .Alloc:
		return arena_alloc(arena, size, alignment);
	case .Free:
		// do nothing
	case .Free_All:
		arena_free_all(arena);
	case .Resize:
		return arena_realloc(arena, old_memory, old_size, size, alignment);
	}

	return nil;
}

arena_allocator :: proc(arena: ^Arena) -> mem.Allocator {
	return {
		procedure = arena_allocator_proc,
		data = arena,
	};
}


Arena_Temp_Memory :: struct {
	arena:  ^Arena,
	cursor: rawptr,
}

arena_begin_temp_memory :: proc(using va: ^Arena) -> Arena_Temp_Memory {
	return {
		arena = va,
		cursor = cursor,
	};
}

// TODO: Don't decommit every single time we end temp memory
//       Maybe achieve this by committing/decommitting in chunks rather than pages.
arena_end_temp_memory :: proc(mark_: Arena_Temp_Memory) {
	using mark := mark_;

	if cursor == nil {
		cursor = arena.base;
	}
	if arena.cursor == nil do return;

	// NOTE(tetra): The cursor is the next location that's valid to return to the user.
	// If it's part way into a page (not at the start of a page), then we cannot decommit that page.
	// We can therefore only decommit the pages after it.

	// TODO(tetra): Decommit at all? Decommit only in chunks and not pages, to reduce syscall count?

	start := enclosing_page(cursor);
	if start < cursor {
		start = next_page(start);
	}

	if arena.cursor > start {
		n := int(uintptr(arena.cursor) - uintptr(start));
		decommit(mem.slice_ptr(cast(^byte)start, n));
		pages := bytes_to_pages(n);
		arena.pages_committed -= pages;
	}

	arena.cursor = cast(^byte) cursor;
}