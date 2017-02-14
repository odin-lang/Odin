#define GB_NO_DEFER
#define GB_IMPLEMENTATION
#include "gb/gb.h"

gbAllocator heap_allocator(void) {
	return gb_heap_allocator();
}

#include "unicode.c"
#include "string.c"
#include "array.c"

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

////////////////////////////////////////////////////////////////
//
// Generic Data Structures
//
////////////////////////////////////////////////////////////////

typedef Array(i32)   Array_i32;
typedef Array(isize) Array_isize;


#define MAP_TYPE String
#define MAP_PROC map_string_
#define MAP_NAME MapString
#include "map.c"

#define MAP_TYPE bool
#define MAP_PROC map_bool_
#define MAP_NAME MapBool
#include "map.c"

#define MAP_TYPE isize
#define MAP_PROC map_isize_
#define MAP_NAME MapIsize
#include "map.c"
