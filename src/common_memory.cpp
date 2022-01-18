
gb_inline void zero_size(void *ptr, isize len) {
	memset(ptr, 0, len);
}

#define zero_item(ptr) zero_size((ptr), gb_size_of(ptr))


template <typename U, typename V>
gb_inline U bit_cast(V &v) { return reinterpret_cast<U &>(v); }

template <typename U, typename V>
gb_inline U const &bit_cast(V const &v) { return reinterpret_cast<U const &>(v); }


gb_inline i64 align_formula(i64 size, i64 align) {
	if (align > 0) {
		i64 result = size + align-1;
		return result - result%align;
	}
	return size;
}
gb_inline isize align_formula_isize(isize size, isize align) {
	if (align > 0) {
		isize result = size + align-1;
		return result - result%align;
	}
	return size;
}
gb_inline void *align_formula_ptr(void *ptr, isize align) {
	if (align > 0) {
		uintptr result = (cast(uintptr)ptr) + align-1;
		return (void *)(result - result%align);
	}
	return ptr;
}


gb_global BlockingMutex global_memory_block_mutex;
gb_global BlockingMutex global_memory_allocator_mutex;

void platform_virtual_memory_init(void);

void virtual_memory_init(void) {
	mutex_init(&global_memory_block_mutex);
	mutex_init(&global_memory_allocator_mutex);
	platform_virtual_memory_init();
}



struct MemoryBlock {
	MemoryBlock *prev;
	u8 *         base; 
	isize        size;
	isize        used;
};

struct Arena {
	MemoryBlock *curr_block;
	isize        minimum_block_size;
	bool         ignore_mutex;
};

enum { DEFAULT_MINIMUM_BLOCK_SIZE = 8ll*1024ll*1024ll };

gb_global isize DEFAULT_PAGE_SIZE = 4096;

MemoryBlock *virtual_memory_alloc(isize size);
void virtual_memory_dealloc(MemoryBlock *block);
void *arena_alloc(Arena *arena, isize min_size, isize alignment);
void arena_free_all(Arena *arena);


isize arena_align_forward_offset(Arena *arena, isize alignment) {
	isize alignment_offset = 0;
	isize ptr = cast(isize)(arena->curr_block->base + arena->curr_block->used);
	isize mask = alignment-1;
	if (ptr & mask) {
		alignment_offset = alignment - (ptr & mask);
	}
	return alignment_offset;
}

void *arena_alloc(Arena *arena, isize min_size, isize alignment) {
	GB_ASSERT(gb_is_power_of_two(alignment));
	
	BlockingMutex *mutex = &global_memory_allocator_mutex;
	if (!arena->ignore_mutex) {
		mutex_lock(mutex);
	}
	
	isize size = 0;
	if (arena->curr_block != nullptr) {
		size = min_size + arena_align_forward_offset(arena, alignment);
	}

	if (arena->curr_block == nullptr || (arena->curr_block->used + size) > arena->curr_block->size) {
		size = align_formula_isize(min_size, alignment);
		arena->minimum_block_size = gb_max(DEFAULT_MINIMUM_BLOCK_SIZE, arena->minimum_block_size);
		
		isize block_size = gb_max(size, arena->minimum_block_size);
		
		MemoryBlock *new_block = virtual_memory_alloc(block_size);
		new_block->prev = arena->curr_block;
		arena->curr_block = new_block;
	}
	
	MemoryBlock *curr_block = arena->curr_block;
	GB_ASSERT((curr_block->used + size) <= curr_block->size);
	
	u8 *ptr = curr_block->base + curr_block->used;
	ptr += arena_align_forward_offset(arena, alignment);
	
	curr_block->used += size;
	GB_ASSERT(curr_block->used <= curr_block->size);
	
	if (!arena->ignore_mutex) {
		mutex_unlock(mutex);
	}
	
	// NOTE(bill): memory will be zeroed by default due to virtual memory 
	return ptr;	
}

void arena_free_all(Arena *arena) {
	while (arena->curr_block != nullptr) {
		MemoryBlock *free_block = arena->curr_block;
		arena->curr_block = free_block->prev;
		virtual_memory_dealloc(free_block);
	}
}


struct PlatformMemoryBlock {
	MemoryBlock block; // IMPORTANT NOTE: must be at the start
	isize total_size;
	PlatformMemoryBlock *prev, *next;
};


gb_global PlatformMemoryBlock global_platform_memory_block_sentinel;

PlatformMemoryBlock *platform_virtual_memory_alloc(isize total_size);
void platform_virtual_memory_free(PlatformMemoryBlock *block);
void platform_virtual_memory_protect(void *memory, isize size);

#if defined(GB_SYSTEM_WINDOWS)
	void platform_virtual_memory_init(void) {
		global_platform_memory_block_sentinel.prev = &global_platform_memory_block_sentinel;	
		global_platform_memory_block_sentinel.next = &global_platform_memory_block_sentinel;
		
		SYSTEM_INFO sys_info = {};
		GetSystemInfo(&sys_info);
		DEFAULT_PAGE_SIZE = gb_max(DEFAULT_PAGE_SIZE, cast(isize)sys_info.dwPageSize);
		GB_ASSERT(gb_is_power_of_two(DEFAULT_PAGE_SIZE));
	}

	PlatformMemoryBlock *platform_virtual_memory_alloc(isize total_size) {
		PlatformMemoryBlock *pmblock = (PlatformMemoryBlock *)VirtualAlloc(0, total_size, MEM_RESERVE|MEM_COMMIT, PAGE_READWRITE);
		GB_ASSERT_MSG(pmblock != nullptr, "Out of Virtual Memory, oh no...");
		return pmblock;
	}
	void platform_virtual_memory_free(PlatformMemoryBlock *block) {
		GB_ASSERT(VirtualFree(block, 0, MEM_RELEASE));
	}
	void platform_virtual_memory_protect(void *memory, isize size) {
		DWORD old_protect = 0;
		BOOL is_protected = VirtualProtect(memory, size, PAGE_NOACCESS, &old_protect);
		GB_ASSERT(is_protected);
	}
#else
	void platform_virtual_memory_init(void) {
		global_platform_memory_block_sentinel.prev = &global_platform_memory_block_sentinel;	
		global_platform_memory_block_sentinel.next = &global_platform_memory_block_sentinel;
		
		DEFAULT_PAGE_SIZE = gb_max(DEFAULT_PAGE_SIZE, cast(isize)sysconf(_SC_PAGE_SIZE));
		GB_ASSERT(gb_is_power_of_two(DEFAULT_PAGE_SIZE));
	}
	
	PlatformMemoryBlock *platform_virtual_memory_alloc(isize total_size) {
		PlatformMemoryBlock *pmblock = (PlatformMemoryBlock *)mmap(nullptr, total_size, PROT_READ | PROT_WRITE, MAP_ANONYMOUS | MAP_PRIVATE, -1, 0);
		GB_ASSERT_MSG(pmblock != nullptr, "Out of Virtual Memory, oh no...");
		return pmblock;
	}
	void platform_virtual_memory_free(PlatformMemoryBlock *block) {
		isize size = block->total_size;
		munmap(block, size);
	}
	void platform_virtual_memory_protect(void *memory, isize size) {
		int err = mprotect(memory, size, PROT_NONE);
		GB_ASSERT(err == 0);
	}
#endif

MemoryBlock *virtual_memory_alloc(isize size) {
	isize const page_size = DEFAULT_PAGE_SIZE; 
	
	isize total_size     = size + gb_size_of(PlatformMemoryBlock);
	isize base_offset    = gb_size_of(PlatformMemoryBlock);
	isize protect_offset = 0;
	
	bool do_protection = false;
	{ // overflow protection
		isize rounded_size = align_formula_isize(size, page_size);
		total_size     = rounded_size + 2*page_size;
		base_offset    = page_size + rounded_size - size;
		protect_offset = page_size + rounded_size;
		do_protection  = true;
	}
	
	PlatformMemoryBlock *pmblock = platform_virtual_memory_alloc(total_size);
	GB_ASSERT_MSG(pmblock != nullptr, "Out of Virtual Memory, oh no...");
	
	pmblock->block.base = cast(u8 *)pmblock + base_offset;
	// Should be zeroed
	GB_ASSERT(pmblock->block.used == 0);
	GB_ASSERT(pmblock->block.prev == nullptr);
	
	if (do_protection) {
		platform_virtual_memory_protect(cast(u8 *)pmblock + protect_offset, page_size);
	}
	
	pmblock->block.size = size;
	pmblock->total_size = total_size;

	PlatformMemoryBlock *sentinel = &global_platform_memory_block_sentinel;
	mutex_lock(&global_memory_block_mutex);
	pmblock->next = sentinel;
	pmblock->prev = sentinel->prev;
	pmblock->prev->next = pmblock;
	pmblock->next->prev = pmblock;
	mutex_unlock(&global_memory_block_mutex);
	
	return &pmblock->block;
}

void virtual_memory_dealloc(MemoryBlock *block_to_free) {
	PlatformMemoryBlock *block = cast(PlatformMemoryBlock *)block_to_free;
	if (block != nullptr) {
		mutex_lock(&global_memory_block_mutex);
		block->prev->next = block->next;
		block->next->prev = block->prev;
		mutex_unlock(&global_memory_block_mutex);
			
		platform_virtual_memory_free(block);
	}
}




GB_ALLOCATOR_PROC(arena_allocator_proc);

gbAllocator arena_allocator(Arena *arena) {
	gbAllocator a;
	a.proc = arena_allocator_proc;
	a.data = arena;
	return a;
}


GB_ALLOCATOR_PROC(arena_allocator_proc) {
	void *ptr = nullptr;
	Arena *arena = cast(Arena *)allocator_data;
	GB_ASSERT_NOT_NULL(arena);

	switch (type) {
	case gbAllocation_Alloc:
		ptr = arena_alloc(arena, size, alignment);
		break;
	case gbAllocation_Free:
		break;
	case gbAllocation_Resize:
		if (size == 0) {
			ptr = nullptr;
		} else if (size <= old_size) {
			ptr = old_memory;
		} else {
			ptr = arena_alloc(arena, size, alignment);
			gb_memmove(ptr, old_memory, old_size);
		}
		break;
	case gbAllocation_FreeAll:
		GB_PANIC("use arena_free_all directly");
		arena_free_all(arena);
		break;
	}

	return ptr;
}


gb_global gb_thread_local Arena permanent_arena = {nullptr, DEFAULT_MINIMUM_BLOCK_SIZE, true};
gbAllocator permanent_allocator() {
	return arena_allocator(&permanent_arena);
}

gbAllocator temporary_allocator() {
	return permanent_allocator();
}






GB_ALLOCATOR_PROC(heap_allocator_proc);

gbAllocator heap_allocator(void) {
	gbAllocator a;
	a.proc = heap_allocator_proc;
	a.data = nullptr;
	return a;
}


GB_ALLOCATOR_PROC(heap_allocator_proc) {
	void *ptr = nullptr;
	gb_unused(allocator_data);
	gb_unused(old_size);



// TODO(bill): Throughly test!
	switch (type) {
#if defined(GB_COMPILER_MSVC)
	case gbAllocation_Alloc:
		if (size == 0) {
			return NULL;
		} else {
			isize aligned_size = align_formula_isize(size, alignment);
			// TODO(bill): Make sure this is aligned correctly
			ptr = HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, aligned_size);
		}
		break;
	case gbAllocation_Free:
		if (old_memory != nullptr) {
			HeapFree(GetProcessHeap(), 0, old_memory);
		}
		break;
	case gbAllocation_Resize:
		if (old_memory != nullptr && size > 0) {
			isize aligned_size = align_formula_isize(size, alignment);
			ptr = HeapReAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, old_memory, aligned_size);
		} else if (old_memory != nullptr) {
			HeapFree(GetProcessHeap(), 0, old_memory);
		} else if (size != 0) {
			isize aligned_size = align_formula_isize(size, alignment);
			// TODO(bill): Make sure this is aligned correctly
			ptr = HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, aligned_size);
		}
		break;
#elif defined(GB_SYSTEM_LINUX)
	// TODO(bill): *nix version that's decent
	case gbAllocation_Alloc: {
		ptr = aligned_alloc(alignment, (size + alignment - 1) & ~(alignment - 1));
		gb_zero_size(ptr, size);
	} break;

	case gbAllocation_Free:
		if (old_memory != nullptr) {
			free(old_memory);
		}
		break;

	case gbAllocation_Resize:
		if (size == 0) {
			if (old_memory != nullptr) {
				free(old_memory);
			}
			break;
		}
		
		alignment = gb_max(alignment, gb_align_of(max_align_t));
		
		if (old_memory == nullptr) {
			ptr = aligned_alloc(alignment, (size + alignment - 1) & ~(alignment - 1));
			gb_zero_size(ptr, size);
			break;
		}
		if (size <= old_size) {
			ptr = old_memory;
			break;
		}

		ptr = aligned_alloc(alignment, (size + alignment - 1) & ~(alignment - 1));
		gb_memmove(ptr, old_memory, old_size);
		free(old_memory);
		gb_zero_size(cast(u8 *)ptr + old_size, gb_max(size-old_size, 0));
		break;
#else
	// TODO(bill): *nix version that's decent
	case gbAllocation_Alloc: {
		int err = 0;
		alignment = gb_max(alignment, gb_align_of(max_align_t));
		
		err = posix_memalign(&ptr, alignment, size);
		GB_ASSERT_MSG(err == 0, "posix_memalign err: %d", err);
		gb_zero_size(ptr, size);
	} break;

	case gbAllocation_Free:
		if (old_memory != nullptr) {
			free(old_memory);
		}
		break;

	case gbAllocation_Resize: {
		int err = 0;
		if (size == 0) {
			free(old_memory);
			break;
		}
		
		alignment = gb_max(alignment, gb_align_of(max_align_t));
		
		if (old_memory == nullptr) {
			err = posix_memalign(&ptr, alignment, size);
			GB_ASSERT_MSG(err == 0, "posix_memalign err: %d", err);
			GB_ASSERT(ptr != nullptr);
			gb_zero_size(ptr, size);
			break;
		}
		if (size <= old_size) {
			ptr = old_memory;
			break;
		}

		err = posix_memalign(&ptr, alignment, size);
		GB_ASSERT_MSG(err == 0, "posix_memalign err: %d", err);
		GB_ASSERT(ptr != nullptr);
		gb_memmove(ptr, old_memory, old_size);
		free(old_memory);
		gb_zero_size(cast(u8 *)ptr + old_size, gb_max(size-old_size, 0));
	} break;
#endif

	case gbAllocation_FreeAll:
		break;
	}

	return ptr;
}


template <typename T>
void resize_array_raw(T **array, gbAllocator const &a, isize old_count, isize new_count) {
	GB_ASSERT(new_count >= 0);
	if (new_count == 0) {
		gb_free(a, *array);
		*array = nullptr;
		return;
	}
	if (new_count < old_count) {
		return;
	}
	isize old_size = old_count * gb_size_of(T);
	isize new_size = new_count * gb_size_of(T);
	isize alignment = gb_align_of(T);
	auto new_data = cast(T *)gb_resize_align(a, *array, old_size, new_size, alignment);
	GB_ASSERT(new_data != nullptr);
	*array = new_data;
}

