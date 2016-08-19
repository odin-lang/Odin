putchar :: proc(c: i32) -> i32 #foreign

mem_compare :: proc(dst, src : rawptr, len: int) -> i32 #foreign "memcmp"
mem_copy    :: proc(dst, src : rawptr, len: int) -> i32 #foreign "memcpy"
mem_move    :: proc(dst, src : rawptr, len: int) -> i32 #foreign "memmove"

debug_trap :: proc() #foreign "llvm.debugtrap"

// TODO(bill): make custom heap procedures
heap_realloc :: proc(ptr: rawptr, sz: int) -> rawptr #foreign "realloc"
heap_alloc   :: proc(sz: int) -> rawptr { return heap_realloc(null, sz); }
heap_free    :: proc(ptr: rawptr)       { _ = heap_realloc(ptr, 0); }


__string_eq :: proc(a, b : string) -> bool {
	if len(a) != len(b) {
		return false;
	}
	if ^a[0] == ^b[0] {
		return true;
	}
	return mem_compare(^a[0], ^b[0], len(a)) == 0;
}

__string_ne :: proc(a, b : string) -> bool {
	return !__string_eq(a, b);
}

__string_cmp :: proc(a, b : string) -> int {
	min_len := len(a);
	if len(b) < min_len {
		min_len = len(b);
	}
	for i := 0; i < min_len; i++ {
		x := a[i];
		y := b[i];
		if x < y {
			return -1;
		} else if x > y {
			return +1;
		}
	}
	if len(a) < len(b) {
		return -1;
	} else if len(a) > len(b) {
		return +1;
	}
	return 0;
}

__string_lt :: proc(a, b : string) -> bool { return __string_cmp(a, b) < 0; }
__string_gt :: proc(a, b : string) -> bool { return __string_cmp(a, b) > 0; }
__string_le :: proc(a, b : string) -> bool { return __string_cmp(a, b) <= 0; }
__string_ge :: proc(a, b : string) -> bool { return __string_cmp(a, b) >= 0; }


type AllocationMode: int;
ALLOCATION_ALLOC       :: 0;
ALLOCATION_DEALLOC     :: 1;
ALLOCATION_DEALLOC_ALL :: 2;
ALLOCATION_RESIZE      :: 3;


type AllocatorProc: proc(allocator_data: rawptr, mode: AllocationMode,
                         size, alignment: int,
                         old_memory: rawptr, old_size: int, flags: u64) -> rawptr;

type Allocator: struct {
	procedure: AllocatorProc,
	data:      rawptr,
}


type Context: struct {
	thread_id: i32,

	user_index: i32,
	user_data:  rawptr,

	allocator: Allocator,
}

#thread_local context: Context;

DEFAULT_ALIGNMENT :: 2*size_of(int);


__check_context :: proc() {
	if context.allocator.procedure == null {
		context.allocator = __default_allocator();
	}

	ptr := __check_context as rawptr;
}


alloc :: proc(size: int) -> rawptr #inline { return alloc_align(size, DEFAULT_ALIGNMENT); }

alloc_align :: proc(size, alignment: int) -> rawptr #inline {
	__check_context();
	a := context.allocator;
	return a.procedure(a.data, ALLOCATION_ALLOC, size, alignment, null, 0, 0);
}

dealloc :: proc(ptr: rawptr) #inline {
	__check_context();
	a := context.allocator;
	_ = a.procedure(a.data, ALLOCATION_DEALLOC, 0, 0, ptr, 0, 0);
}
dealloc_all :: proc(ptr: rawptr) #inline {
	__check_context();
	a := context.allocator;
	_ = a.procedure(a.data, ALLOCATION_DEALLOC_ALL, 0, 0, ptr, 0, 0);
}


resize       :: proc(ptr: rawptr, old_size, new_size: int) -> rawptr #inline { return resize_align(ptr, old_size, new_size, DEFAULT_ALIGNMENT); }
resize_align :: proc(ptr: rawptr, old_size, new_size, alignment: int) -> rawptr #inline {
	__check_context();
	a := context.allocator;
	return a.procedure(a.data, ALLOCATION_RESIZE, new_size, alignment, ptr, old_size, 0);
}



default_resize_align :: proc(old_memory: rawptr, old_size, new_size, alignment: int) -> rawptr {
	if old_memory == null {
		return alloc_align(new_size, alignment);
	}

	if new_size == 0 {
		dealloc(old_memory);
		return null;
	}

	if new_size < old_size {
		new_size = old_size;
	}

	if old_size == new_size {
		return old_memory;
	}

	new_memory := alloc_align(new_size, alignment);
	if new_memory == null {
		return null;
	}
	_ = copy((new_memory as ^u8)[:new_size], (old_memory as ^u8)[:old_size]);
	dealloc(old_memory);
	return new_memory;
}


__default_allocator_proc :: proc(allocator_data: rawptr, mode: AllocationMode,
                                 size, alignment: int,
                                 old_memory: rawptr, old_size: int, flags: u64) -> rawptr {
	if mode == ALLOCATION_ALLOC {
		return heap_alloc(size);
	} else if mode == ALLOCATION_RESIZE {
		return heap_realloc(old_memory, size);
	} else if mode == ALLOCATION_DEALLOC {
		heap_free(old_memory);
	} else if mode == ALLOCATION_DEALLOC_ALL {
		// NOTE(bill): Does nothing
	}

	return null;
}

__default_allocator :: proc() -> Allocator {
	return Allocator{
		__default_allocator_proc,
		null,
	};
}

