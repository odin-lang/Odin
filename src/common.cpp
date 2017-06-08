#if defined(GB_SYSTEM_UNIX)
// Required for intrinsics on GCC
#include <xmmintrin.h>
#endif

#define GB_NO_DEFER
#define GB_IMPLEMENTATION
#include "gb/gb.h"

#include <math.h>

gbAllocator heap_allocator(void) {
	return gb_heap_allocator();
}

#include "unicode.cpp"
#include "string.cpp"
#include "array.cpp"
#include "integer128.cpp"
#include "murmurhash3.cpp"
#include "map.cpp"

u128 fnv128a(void const *data, isize len) {
	u128 o = u128_lo_hi(0x13bull, 0x1000000ull);
	u128 h = u128_lo_hi(0x62b821756295c58dull, 0x6c62272e07bb0142ull);
	u8 const *bytes = cast(u8 const *)data;
	for (isize i = 0; i < len; i++) {
		h = u128_mul(u128_xor(h, u128_from_u64(bytes[i])), o);
	}
	return h;
}

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


struct DynamicArenaBlock {
	DynamicArenaBlock *prev;
	DynamicArenaBlock *next;
	u8 *               start;
	isize              count;
	isize              capacity;

	gbVirtualMemory    vm;
};

struct DynamicArena {
	DynamicArenaBlock *start_block;
	DynamicArenaBlock *current_block;
	isize              block_size;
};

DynamicArenaBlock *add_dynamic_arena_block(DynamicArena *a) {
	GB_ASSERT(a != NULL);
	GB_ASSERT(a->block_size > 0);

	gbVirtualMemory vm = gb_vm_alloc(NULL, a->block_size);
	DynamicArenaBlock *block = cast(DynamicArenaBlock *)vm.data;

	u8 *start = cast(u8 *)gb_align_forward(cast(u8 *)(block + 1), GB_DEFAULT_MEMORY_ALIGNMENT);
	u8 *end = cast(u8 *)vm.data + vm.size;

	block->vm       = vm;
	block->start    = start;
	block->count    = 0;
	block->capacity = end-start;

	if (a->current_block != NULL) {
		a->current_block->next = block;
		block->prev = a->current_block;
	}
	a->current_block = block;
	return block;
}

void init_dynamic_arena(DynamicArena *a, isize block_size) {
	isize size = gb_size_of(DynamicArenaBlock) + block_size;
	size = cast(isize)gb_align_forward(cast(void *)cast(uintptr)size, GB_DEFAULT_MEMORY_ALIGNMENT);
	a->block_size = size;
	a->start_block = add_dynamic_arena_block(a);
}

void destroy_dynamic_arena(DynamicArena *a) {
	DynamicArenaBlock *b = a->current_block;
	while (b != NULL) {
		gbVirtualMemory vm = b->vm;
		b = b->prev;
		gb_vm_free(b->vm);
	}
}

GB_ALLOCATOR_PROC(dynamic_arena_allocator_proc) {
	DynamicArena *a = cast(DynamicArena *)allocator_data;
	void *ptr = NULL;

	switch (type) {
	case gbAllocation_Alloc: {

	} break;

	case gbAllocation_Free: {
	} break;

	case gbAllocation_Resize: {
	} break;

	case gbAllocation_FreeAll:
		GB_PANIC("free_all is not supported by this allocator");
		break;
	}

	return ptr;
}

gbAllocator dynamic_arena_allocator(DynamicArena *a) {
	gbAllocator allocator = {dynamic_arena_allocator_proc, a};
	return allocator;
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



#define for_array(index_, array_) for (isize index_ = 0; index_ < (array_).count; index_++)


// Doubly Linked Lists

#define DLIST_SET(curr_element, next_element)  do { \
	(curr_element)->next = (next_element);             \
	(curr_element)->next->prev = (curr_element);       \
	(curr_element) = (curr_element)->next;             \
} while (0)

#define DLIST_APPEND(root_element, curr_element, next_element) do { \
	if ((root_element) == NULL) { \
		(root_element) = (curr_element) = (next_element); \
	} else { \
		DLIST_SET(curr_element, next_element); \
	} \
} while (0)


