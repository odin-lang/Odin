#load "win32.odin"

debug_trap :: proc() #foreign "llvm.debugtrap"

// TODO(bill): make custom heap procedures
heap_alloc :: proc(len: int) -> rawptr {
	return HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, len);
}
heap_free :: proc(ptr: rawptr) {
	_ = HeapFree(GetProcessHeap(), 0, ptr);
}


memory_compare :: proc(dst, src: rawptr, len: int) -> int {
	s1, s2: ^u8 = dst, src;
	for i := 0; i < len; i++ {
		if s1[i] != s2[i] {
			return (s1[i] - s2[i]) as int;
		}
	}
	return 0;
}

memory_copy :: proc(dst, src: rawptr, n: int) #inline {
	if dst == src {
		return;
	}

	v128b :: type {4}u32;
	static_assert(align_of(v128b) == 16);

	d, s: ^u8 = dst, src;

	for ; s as uint % 16 != 0 && n != 0; n-- {
		d[0] = s[0];
		d, s = ^d[1], ^s[1];
	}

	if d as uint % 16 == 0 {
		for ; n >= 16; d, s, n = ^d[16], ^s[16], n-16 {
			(d as ^v128b)[0] = (s as ^v128b)[0];
		}

		if n&8 != 0 {
			(d as ^u64)[0] = (s as ^u64)[0];
			d, s = ^d[8], ^s[8];
		}
		if n&4 != 0 {
			(d as ^u32)[0] = (s as ^u32)[0];
			d, s = ^d[4], ^s[4];
		}
		if n&2 != 0 {
			(d as ^u16)[0] = (s as ^u16)[0];
			d, s = ^d[2], ^s[2];
		}
		if n&1 != 0 {
			d[0] = s[0];
			d, s = ^d[1], ^s[1];
		}
		return;
	}

	// IMPORTANT NOTE(bill): Little endian only
	LS :: proc(a, b: u32) -> u32 #inline { return a << b; }
	RS :: proc(a, b: u32) -> u32 #inline { return a >> b; }
	/* NOTE(bill): Big endian version
	LS :: proc(a, b: u32) -> u32 #inline { return a >> b; }
	RS :: proc(a, b: u32) -> u32 #inline { return a << b; }
	*/

	w, x: u32;

	if d as uint % 4 == 1 {
		w = (s as ^u32)^;
		d[0] = s[0];
		d[1] = s[1];
		d[2] = s[2];
		d, s, n = ^d[3], ^s[3], n-3;

		for n > 16 {
			d32 := d as ^u32;
			x = (^s[1]  as ^u32)^; d32[0] = LS(w, 24) | RS(x, 8);
			w = (^s[5]  as ^u32)^; d32[1] = LS(x, 24) | RS(w, 8);
			x = (^s[9]  as ^u32)^; d32[2] = LS(w, 24) | RS(x, 8);
			w = (^s[13] as ^u32)^; d32[3] = LS(x, 24) | RS(w, 8);

			d, s, n = ^d[16], ^s[16], n-16;
		}

	} else if d as uint % 4 == 2 {
		w = (s as ^u32)^;
		d[0] = s[0];
		d[1] = s[1];
		d, s, n = ^d[2], ^s[2], n-2;

		for n > 17 {
			d32 := d as ^u32;
			x = (^s[2]  as ^u32)^; d32[0] = LS(w, 16) | RS(x, 16);
			w = (^s[6]  as ^u32)^; d32[1] = LS(x, 16) | RS(w, 16);
			x = (^s[10] as ^u32)^; d32[2] = LS(w, 16) | RS(x, 16);
			w = (^s[14] as ^u32)^; d32[3] = LS(x, 16) | RS(w, 16);

			d, s, n = ^d[16], ^s[16], n-16;
		}

	} else if d as uint % 4 == 3 {
		w = (s as ^u32)^;
		d[0] = s[0];
		d, s, n = ^d[1], ^s[1], n-1;

		for n > 18 {
			d32 := d as ^u32;
			x = (^s[3]  as ^u32)^; d32[0] = LS(w, 8) | RS(x, 24);
			w = (^s[7]  as ^u32)^; d32[1] = LS(x, 8) | RS(w, 24);
			x = (^s[11] as ^u32)^; d32[2] = LS(w, 8) | RS(x, 24);
			w = (^s[15] as ^u32)^; d32[3] = LS(x, 8) | RS(w, 24);

			d, s, n = ^d[16], ^s[16], n-16;
		}
	}

	if n&16 != 0 {
		(d as ^v128b)[0] = (s as ^v128b)[0];
		d, s = ^d[16], ^s[16];
	}
	if n&8 != 0 {
		(d as ^u64)[0] = (s as ^u64)[0];
		d, s = ^d[8], ^s[8];
	}
	if n&4 != 0 {
		(d as ^u32)[0] = (s as ^u32)[0];
		d, s = ^d[4], ^s[4];
	}
	if n&2 != 0 {
		(d as ^u16)[0] = (s as ^u16)[0];
		d, s = ^d[2], ^s[2];
	}
	if n&1 != 0 {
		d[0]  = s[0];
	}
}

memory_move :: proc(dst, src: rawptr, n: int) #inline {
	d, s: ^u8 = dst, src;
	if d == s {
		return;
	}
	if d >= ^s[n] || ^d[n] <= s {
		memory_copy(d, s, n);
		return;
	}

	// TODO(bill): Vectorize the shit out of this
	if d < s {
		if s as int % size_of(int) == d as int % size_of(int) {
			for d as int % size_of(int) != 0 {
				if n == 0 {
					return;
				}
				n--;
				d[0] = s[0];
				d, s = ^d[1], ^s[1];
			}
			di, si := d as ^int, s as ^int;
			for n >= size_of(int) {
				di[0] = si[0];
				di, si = ^di[1], ^si[1];
				n -= size_of(int);
			}
		}
		for ; n > 0; n-- {
			d[0] = s[0];
			d, s = ^d[1], ^s[1];
		}
	} else {
		if s as int % size_of(int) == d as int % size_of(int) {
			for ^d[n] as int % size_of(int) != 0 {
				if n == 0 {
					return;
				}
				n--;
				d[0] = s[0];
				d, s = ^d[1], ^s[1];
			}
			for n >= size_of(int) {
				n -= size_of(int);
				di, si := ^d[n] as ^int, ^s[n] as ^int;
				di[0] = si[0];
			}
			for ; n > 0; n-- {
				d[0] = s[0];
				d, s = ^d[1], ^s[1];
			}
		}
		for n > 0 {
			n--;
			d[n] = s[n];
		}
	}
}

__string_eq :: proc(a, b : string) -> bool {
	if len(a) != len(b) {
		return false;
	}
	if ^a[0] == ^b[0] {
		return true;
	}
	return memory_compare(^a[0], ^b[0], len(a)) == 0;
}

__string_ne :: proc(a, b : string) -> bool #inline {
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

__string_lt :: proc(a, b : string) -> bool #inline { return __string_cmp(a, b) < 0; }
__string_gt :: proc(a, b : string) -> bool #inline { return __string_cmp(a, b) > 0; }
__string_le :: proc(a, b : string) -> bool #inline { return __string_cmp(a, b) <= 0; }
__string_ge :: proc(a, b : string) -> bool #inline { return __string_cmp(a, b) >= 0; }




AllocationMode :: type enum {
	ALLOC,
	DEALLOC,
	DEALLOC_ALL,
	RESIZE,
}



AllocatorProc :: type proc(allocator_data: rawptr, mode: AllocationMode,
                           size, alignment: int,
                           old_memory: rawptr, old_size: int, flags: u64) -> rawptr;

Allocator :: type struct {
	procedure: AllocatorProc,
	data:      rawptr,
}


Context :: type struct {
	thread_id: i32,

	user_index: i32,
	user_data:  rawptr,

	allocator: Allocator,
}

#thread_local context: Context;

DEFAULT_ALIGNMENT :: 2*size_of(int);


__check_context :: proc() {
	static_assert(AllocationMode.ALLOC == 0);
	static_assert(AllocationMode.DEALLOC == 1);
	static_assert(AllocationMode.DEALLOC_ALL == 2);
	static_assert(AllocationMode.RESIZE == 3);

	if context.allocator.procedure == null {
		context.allocator = __default_allocator();
	}
}


alloc :: proc(size: int) -> rawptr #inline { return alloc_align(size, DEFAULT_ALIGNMENT); }

alloc_align :: proc(size, alignment: int) -> rawptr #inline {
	__check_context();
	a := context.allocator;
	return a.procedure(a.data, AllocationMode.ALLOC, size, alignment, null, 0, 0);
}

dealloc :: proc(ptr: rawptr) #inline {
	__check_context();
	a := context.allocator;
	_ = a.procedure(a.data, AllocationMode.DEALLOC, 0, 0, ptr, 0, 0);
}
dealloc_all :: proc(ptr: rawptr) #inline {
	__check_context();
	a := context.allocator;
	_ = a.procedure(a.data, AllocationMode.DEALLOC_ALL, 0, 0, ptr, 0, 0);
}


resize       :: proc(ptr: rawptr, old_size, new_size: int) -> rawptr #inline { return resize_align(ptr, old_size, new_size, DEFAULT_ALIGNMENT); }
resize_align :: proc(ptr: rawptr, old_size, new_size, alignment: int) -> rawptr #inline {
	__check_context();
	a := context.allocator;
	return a.procedure(a.data, AllocationMode.RESIZE, new_size, alignment, ptr, old_size, 0);
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
	if mode == AllocationMode.ALLOC {
		return heap_alloc(size);
	} else if mode == AllocationMode.RESIZE {
		return default_resize_align(old_memory, old_size, size, alignment);
	} else if mode == AllocationMode.DEALLOC {
		heap_free(old_memory);
	} else if mode == AllocationMode.DEALLOC_ALL {
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

