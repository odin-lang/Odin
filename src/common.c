#define GB_NO_DEFER
#define GB_IMPLEMENTATION
#include "gb/gb.h"

gbAllocator heap_allocator(void) {
	return gb_heap_allocator();
}

#include "string.c"
#include "array.c"

gb_global String global_module_path = {0};
gb_global bool global_module_path_set = false;


String get_module_dir() {
	if (global_module_path_set) {
		return global_module_path;
	}

	Array(wchar_t) path_buf;
	array_init_count(&path_buf, heap_allocator(), 300);

	isize len = 0;
	for (;;) {
		len = GetModuleFileNameW(NULL, &path_buf.e[0], path_buf.count);
		if (len == 0) {
			return make_string(NULL, 0);
		}
		if (len < path_buf.count) {
			break;
		}
		array_resize(&path_buf, 2*path_buf.count + 300);
	}

	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&string_buffer_arena);

	wchar_t *text = gb_alloc_array(string_buffer_allocator, wchar_t, len+1);

	GetModuleFileNameW(NULL, text, len);
	String path = string16_to_string(heap_allocator(), make_string16(text, len));
	for (isize i = path.len-1; i >= 0; i--) {
		u8 c = path.text[i];
		if (c == '/' || c == '\\') {
			break;
		}
		path.len--;
	}

	global_module_path = path;
	global_module_path_set = true;

	gb_temp_arena_memory_end(tmp);

	array_free(&path_buf);

	return path;
}

String path_to_fullpath(gbAllocator a, String s) {
	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&string_buffer_arena);
	String16 string16 = string_to_string16(string_buffer_allocator, s);
	String result = {0};

	DWORD len = GetFullPathNameW(string16.text, 0, NULL, NULL);
	if (len != 0) {
		wchar_t *text = gb_alloc_array(string_buffer_allocator, wchar_t, len+1);
		GetFullPathNameW(string16.text, len, text, NULL);
		text[len] = 0;
		result = string16_to_string(a, make_string16(text, len));
	}
	gb_temp_arena_memory_end(tmp);
	return result;
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
			for (j = 0; j < 10; j++)
				f *= f; /* NOTE(bill): Cause overflow */

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
