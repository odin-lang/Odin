#if defined(GB_SYSTEM_UNIX)
// Required for intrinsics on GCC
#include <xmmintrin.h>
#endif

#define GB_IMPLEMENTATION
#include "gb/gb.h"


#include <wchar.h>
#include <stdio.h>

#include <math.h>

GB_ALLOCATOR_PROC(heap_allocator_proc);

gbAllocator heap_allocator(void) {
	gbAllocator a;
	a.proc = heap_allocator_proc;
	a.data = NULL;
	return a;
}


GB_ALLOCATOR_PROC(heap_allocator_proc) {
	void *ptr = NULL;
	gb_unused(allocator_data);
	gb_unused(old_size);
// TODO(bill): Throughly test!
	switch (type) {
#if defined(GB_COMPILER_MSVC)
	case gbAllocation_Alloc:
		ptr = _aligned_malloc(size, alignment);
		if (flags & gbAllocatorFlag_ClearToZero)
			gb_zero_size(ptr, size);
		break;
	case gbAllocation_Free:
		_aligned_free(old_memory);
		break;
	case gbAllocation_Resize:
		ptr = _aligned_realloc(old_memory, size, alignment);
		break;

#elif defined(GB_SYSTEM_LINUX)
	// TODO(bill): *nix version that's decent
	case gbAllocation_Alloc: {
		ptr = aligned_alloc(alignment, size);
		// ptr = malloc(size+alignment);

		if (flags & gbAllocatorFlag_ClearToZero) {
			gb_zero_size(ptr, size);
		}
	} break;

	case gbAllocation_Free: {
		free(old_memory);
	} break;

	case gbAllocation_Resize: {
		// ptr = realloc(old_memory, size);
		ptr = gb_default_resize_align(heap_allocator(), old_memory, old_size, size, alignment);
	} break;
#else
	// TODO(bill): *nix version that's decent
	case gbAllocation_Alloc: {
		posix_memalign(&ptr, alignment, size);

		if (flags & gbAllocatorFlag_ClearToZero) {
			gb_zero_size(ptr, size);
		}
	} break;

	case gbAllocation_Free: {
		free(old_memory);
	} break;

	case gbAllocation_Resize: {
		ptr = gb_default_resize_align(heap_allocator(), old_memory, old_size, size, alignment);
	} break;
#endif

	case gbAllocation_FreeAll:
		break;
	}

	return ptr;
}

#include "unicode.cpp"
#include "string.cpp"
#include "array.cpp"
#include "integer128.cpp"
#include "murmurhash3.cpp"

#define for_array(index_, array_) for (isize index_ = 0; index_ < (array_).count; index_++)


u128 fnv128a(void const *data, isize len) {
	u128 o = u128_lo_hi(0x13bull, 0x1000000ull);
	u128 h = u128_lo_hi(0x62b821756295c58dull, 0x6c62272e07bb0142ull);
	u8 const *bytes = cast(u8 const *)data;
	for (isize i = 0; i < len; i++) {
		h.lo ^= bytes[i];
		h = h * o;
	}
	return h;
}

#include "map.cpp"
#include "ptr_set.cpp"
#include "priority_queue.cpp"



gb_global String global_module_path = {0};
gb_global bool global_module_path_set = false;

gb_global gbScratchMemory scratch_memory = {0};

void init_scratch_memory(isize size) {
	void *memory = gb_alloc(heap_allocator(), size);
	gb_scratch_memory_init(&scratch_memory, memory, size);
}

gbAllocator scratch_allocator(void) {
	return gb_scratch_allocator(&scratch_memory);
}

struct Pool {
	isize       memblock_size;
	isize       out_of_band_size;
	isize       alignment;

	Array<u8 *> unused_memblock;
	Array<u8 *> used_memblock;
	Array<u8 *> out_of_band_allocations;

	u8 *        current_memblock;
	u8 *        current_pos;
	isize       bytes_left;

	gbAllocator block_allocator;
};

enum {
	POOL_BUCKET_SIZE_DEFAULT      = 65536,
	POOL_OUT_OF_BAND_SIZE_DEFAULT = 6554,
};

void pool_init(Pool *pool,
               isize memblock_size = POOL_BUCKET_SIZE_DEFAULT,
               isize out_of_band_size = POOL_OUT_OF_BAND_SIZE_DEFAULT,
               isize alignment = 8,
               gbAllocator block_allocator = heap_allocator(),
               gbAllocator array_allocator = heap_allocator()) {
	pool->memblock_size = memblock_size;
	pool->out_of_band_size = out_of_band_size;
	pool->alignment = alignment;
	pool->block_allocator = block_allocator;

	array_init(&pool->unused_memblock,         array_allocator);
	array_init(&pool->used_memblock,           array_allocator);
	array_init(&pool->out_of_band_allocations, array_allocator);
}

void pool_free_all(Pool *p) {
	if (p->current_memblock != nullptr) {
		array_add(&p->unused_memblock, p->current_memblock);
		p->current_memblock = nullptr;
	}

	for_array(i, p->used_memblock) {
		array_add(&p->unused_memblock, p->used_memblock[i]);
	}
	array_clear(&p->unused_memblock);

	for_array(i, p->out_of_band_allocations) {
		gb_free(p->block_allocator, p->out_of_band_allocations[i]);
	}
	array_clear(&p->out_of_band_allocations);
}

void pool_destroy(Pool *p) {
	pool_free_all(p);

	for_array(i, p->unused_memblock) {
		gb_free(p->block_allocator, p->unused_memblock[i]);
	}
}

void pool_cycle_new_block(Pool *p) {
	GB_ASSERT_MSG(p->block_allocator.proc != nullptr,
	              "You must call pool_init on a Pool before using it!");

	if (p->current_memblock != nullptr) {
		array_add(&p->used_memblock, p->current_memblock);
	}

	u8 *new_block = nullptr;

	if (p->unused_memblock.count > 0) {
		new_block = array_pop(&p->unused_memblock);
	} else {
		GB_ASSERT(p->block_allocator.proc != nullptr);
		new_block = cast(u8 *)gb_alloc_align(p->block_allocator, p->memblock_size, p->alignment);
	}

	p->bytes_left       = p->memblock_size;
	p->current_memblock = new_block;
	p->current_memblock = new_block;
}

void *pool_get(Pool *p,
               isize size, isize alignment = 0) {
	if (alignment <= 0) alignment = p->alignment;

	isize extra = alignment - (size & alignment);
	size += extra;
	if (size >= p->out_of_band_size) {
		GB_ASSERT(p->block_allocator.proc != nullptr);
		u8 *memory = cast(u8 *)gb_alloc_align(p->block_allocator, p->memblock_size, alignment);
		if (memory != nullptr) {
			array_add(&p->out_of_band_allocations, memory);
		}
		return memory;
	}

	if (p->bytes_left < size) {
		pool_cycle_new_block(p);
		if (p->current_memblock != nullptr) {
			return nullptr;
		}
	}

	u8 *res = p->current_pos;
	p->current_pos += size;
	p->bytes_left  -= size;
	return res;
}


gbAllocator pool_allocator(Pool *pool);

GB_ALLOCATOR_PROC(pool_allocator_procedure) {
	Pool *p = cast(Pool *)allocator_data;
	void *ptr = nullptr;

	switch (type) {
	case gbAllocation_Alloc:
		return pool_get(p, size, alignment);
	case gbAllocation_Free:
		// Does nothing
		break;
	case gbAllocation_FreeAll:
		pool_free_all(p);
		break;
	case gbAllocation_Resize:
		return gb_default_resize_align(pool_allocator(p), old_memory, old_size, size, alignment);
	}

	return ptr;
}

gbAllocator pool_allocator(Pool *pool) {
	gbAllocator allocator;
	allocator.proc = pool_allocator_procedure;
	allocator.data = pool;
	return allocator;
}



i32 next_pow2(i32 n) {
	if (n <= 0) {
		return 0;
	}
	n--;
	n |= n >> 1;
	n |= n >> 2;
	n |= n >> 4;
	n |= n >> 8;
	n |= n >> 16;
	n++;
	return n;
}
i64 next_pow2(i64 n) {
	if (n <= 0) {
		return 0;
	}
	n--;
	n |= n >> 1;
	n |= n >> 2;
	n |= n >> 4;
	n |= n >> 8;
	n |= n >> 16;
	n |= n >> 32;
	n++;
	return n;
}

i32 prev_pow2(i32 n) {
	if (n <= 0) {
		return 0;
	}
	n |= n >> 1;
	n |= n >> 2;
	n |= n >> 4;
	n |= n >> 8;
	n |= n >> 16;
	return n - (n >> 1);
}
i64 prev_pow2(i64 n) {
	if (n <= 0) {
		return 0;
	}
	n |= n >> 1;
	n |= n >> 2;
	n |= n >> 4;
	n |= n >> 8;
	n |= n >> 16;
	n |= n >> 32;
	return n - (n >> 1);
}

i16 f32_to_f16(f32 value) {
	union { u32 i; f32 f; } v;
	i32 i, s, e, m;

	v.f = value;
	i = (i32)v.i;

	s =  (i >> 16) & 0x00008000;
	e = ((i >> 23) & 0x000000ff) - (127 - 15);
	m =   i        & 0x007fffff;


	if (e <= 0) {
		if (e < -10) return cast(i16)s;
		m = (m | 0x00800000) >> (1 - e);

		if (m & 0x00001000)
			m += 0x00002000;

		return cast(i16)(s | (m >> 13));
	} else if (e == 0xff - (127 - 15)) {
		if (m == 0) {
			return cast(i16)(s | 0x7c00); /* NOTE(bill): infinity */
		} else {
			/* NOTE(bill): NAN */
			m >>= 13;
			return cast(i16)(s | 0x7c00 | m | (m == 0));
		}
	} else {
		if (m & 0x00001000) {
			m += 0x00002000;
			if (m & 0x00800000) {
				m = 0;
				e += 1;
			}
		}

		if (e > 30) {
			float volatile f = 1e12f;
			int j;
			for (j = 0; j < 10; j++) {
				f *= f; /* NOTE(bill): Cause overflow */
			}

			return cast(i16)(s | 0x7c00);
		}

		return cast(i16)(s | (e << 10) | (m >> 13));
	}
}

f64 gb_sqrt(f64 x) {
	return sqrt(x);
}





// Doubly Linked Lists

#define DLIST_SET(curr_element, next_element)  do { \
	(curr_element)->next = (next_element);             \
	(curr_element)->next->prev = (curr_element);       \
	(curr_element) = (curr_element)->next;             \
} while (0)

#define DLIST_APPEND(root_element, curr_element, next_element) do { \
	if ((root_element) == nullptr) { \
		(root_element) = (curr_element) = (next_element); \
	} else { \
		DLIST_SET(curr_element, next_element); \
	} \
} while (0)



#if defined(GB_SYSTEM_WINDOWS)

wchar_t **command_line_to_wargv(wchar_t *cmd_line, int *_argc) {
	u32 i, j;

	u32 len = cast(u32)string16_len(cmd_line);
	i = ((len+2)/2)*gb_size_of(void *) + gb_size_of(void *);

	wchar_t **argv = cast(wchar_t **)GlobalAlloc(GMEM_FIXED, i + (len+2)*gb_size_of(wchar_t));
	wchar_t *_argv = cast(wchar_t *)((cast(u8 *)argv)+i);

	u32 argc = 0;
	argv[argc] = _argv;
	bool in_quote = false;
	bool in_text = false;
	bool in_space = true;
	i = 0;
	j = 0;

	for (;;) {
		wchar_t a = cmd_line[i];
		if (a == 0) {
			break;
		}
		if (in_quote) {
			if (a == '\"') {
				in_quote = false;
			} else {
				_argv[j++] = a;
			}
		} else {
			switch (a) {
			case '\"':
				in_quote = true;
				in_text = true;
				if (in_space) argv[argc++] = _argv+j;
				in_space = false;
				break;
			case ' ':
			case '\t':
			case '\n':
			case '\r':
				if (in_text) _argv[j++] = '\0';
				in_text = false;
				in_space = true;
				break;
			default:
				in_text = true;
				if (in_space) argv[argc++] = _argv+j;
				_argv[j++] = a;
				in_space = false;
				break;
			}
		}
		i++;
	}
	_argv[j] = '\0';
	argv[argc] = nullptr;

	if (_argc) *_argc = argc;
	return argv;
}

#endif


#if defined(GB_SYSTEM_WINDOWS)
	bool path_is_directory(String path) {
		gbAllocator a = heap_allocator();
		String16 wstr = string_to_string16(a, path);
		defer (gb_free(a, wstr.text));

		i32 attribs = GetFileAttributesW(wstr.text);
		if (attribs < 0) return false;

		return (attribs & FILE_ATTRIBUTE_DIRECTORY) != 0;
	}

#else
	bool path_is_directory(String path) {
		gbAllocator a = heap_allocator();
		char *copy = cast(char *)copy_string(a, path).text;
		defer (gb_free(a, copy));

		struct stat s;
		if (stat(copy, &s) == 0) {
			return (s.st_mode & S_IFDIR) != 0;
		}
		return false;
	}
#endif

