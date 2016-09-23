// #define GB_NO_WINDOWS_H
#define GB_IMPLEMENTATION
#include "gb/gb.h"

#include "string.cpp"

String get_module_dir(gbAllocator a) {
	isize len = GetModuleFileNameW(NULL, NULL, 0);
	if (len == 0) {
		return make_string(NULL, 0);
	}
	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&string_buffer_arena);
	defer (gb_temp_arena_memory_end(tmp));

	
	wchar_t *text = gb_alloc_array(string_buffer_allocator, wchar_t, len+1);

	String16 str = {text, len};
	GetModuleFileNameW(NULL, text, len);
	String path = string16_to_string(a, str);
	for (isize i = path.len-1; i >= 0; i--) {
		u8 c = path.text[i];
		if (c == '/' || c == '\\') {
			break;
		}
		path.len--;
	}
	
	return path;
}

String path_to_fullpath(gbAllocator a, String s) {
	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&string_buffer_arena);
	defer (gb_temp_arena_memory_end(tmp));

	String16 string16 = string_to_string16(string_buffer_allocator, s);

	DWORD len = GetFullPathNameW(string16.text, 0, NULL, NULL);
	if (len == 0) {
		return make_string(NULL, 0);
	}
	wchar_t *text = gb_alloc_array(string_buffer_allocator, wchar_t, len+1);
	GetFullPathNameW(string16.text, len, text, NULL);
	text[len] = 0;

	return string16_to_string(a, make_string16(text, len));
}

struct BlockTimer {
	u64 start;
	u64 finish;
	char *msg;
	BlockTimer(char *msg) : msg(msg) {
		start = gb_utc_time_now();
	}
	~BlockTimer() {
		finish = gb_utc_time_now();
		gb_printf_err("%s - %llu us\n", finish-start);
	}
};


// Hasing

struct HashKey {
	u64 key;
	b32 is_string;
	String string; // if String, s.len > 0
};

gb_inline HashKey hashing_proc(void const *data, isize len) {
	HashKey h = {};
	// h.key = gb_murmur64(data, len);
	h.key = gb_fnv64a(data, len);
	return h;
}

gb_inline HashKey hash_string(String s) {
	HashKey h = hashing_proc(s.text, s.len);
	h.is_string = true;
	h.string = s;
	return h;
}

gb_inline HashKey hash_pointer(void *ptr) {
	uintptr p = cast(uintptr)ptr;
	HashKey h = {cast(u64)p};
	return h;
}

b32 hash_key_equal(HashKey a, HashKey b) {
	if (a.key == b.key) {
		// NOTE(bill): If two string's hashes collide, compare the strings themselves
		if (a.is_string) {
			if (b.is_string) return a.string == b.string;
			return false;
		}
		return true;
	}
	return false;
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


#define gb_for_array(index_, array_) for (isize index_ = 0; (array_) != NULL && index_ < gb_array_count(array_); index_++)


// Doubly Linked Lists

#define DLIST_SET(curr_element, next_element)  do { \
	(curr_element)->next = (next_element);             \
	(curr_element)->next->prev = (curr_element);       \
	(curr_element) = (curr_element)->next;             \
} while (0)

#define DLIST_APPEND(root_element, curr_element, next_element) do { \
	if ((root_element) == NULL) \
		(root_element) = (curr_element) = (next_element); \
	else \
		DLIST_SET(curr_element, next_element); \
} while (0)

////////////////////////////////////////////////////////////////
//
// Generic Data Structures
//
////////////////////////////////////////////////////////////////


struct MapFindResult {
	isize hash_index;
	isize entry_prev;
	isize entry_index;
};

template <typename T>
struct MapEntry {
	HashKey key;
	isize   next;
	T       value;
};

template <typename T>
struct Map {
	gbArray(isize) hashes;
	gbArray(MapEntry<T>) entries;
};

template <typename T> void map_init   (Map<T> *h, gbAllocator a);
template <typename T> void map_destroy(Map<T> *h);
template <typename T> T *  map_get    (Map<T> *h, HashKey key);
template <typename T> void map_set    (Map<T> *h, HashKey key, T value);
template <typename T> void map_remove (Map<T> *h, HashKey key);
template <typename T> void map_clear  (Map<T> *h);
template <typename T> void map_grow   (Map<T> *h);
template <typename T> void map_rehash (Map<T> *h, isize new_count);

template <typename T> typename MapEntry<T> *multi_map_find_first(Map<T> *h, HashKey key);
template <typename T> typename MapEntry<T> *multi_map_find_next (Map<T> *h, typename MapEntry<T> *e);

template <typename T> isize multi_map_count     (Map<T> *h, HashKey key);
template <typename T> void  multi_map_get_all   (Map<T> *h, HashKey key, T *items);
template <typename T> void  multi_map_insert    (Map<T> *h, HashKey key, T value);
template <typename T> void  multi_map_remove    (Map<T> *h, HashKey key, typename MapEntry<T> *e);
template <typename T> void  multi_map_remove_all(Map<T> *h, HashKey key);



template <typename T>
gb_inline void map_init(Map<T> *h, gbAllocator a) {
	gb_array_init(h->hashes,  a);
	gb_array_init(h->entries, a);
}

template <typename T>
gb_inline void map_destroy(Map<T> *h) {
	if (h->entries) gb_array_free(h->entries);
	if (h->hashes)  gb_array_free(h->hashes);
}

template <typename T>
gb_internal isize map__add_entry(Map<T> *h, HashKey key) {
	MapEntry<T> e = {0};
	e.key = key;
	e.next = -1;
	gb_array_append(h->entries, e);
	return gb_array_count(h->entries)-1;
}

template <typename T>
gb_internal MapFindResult map__find(Map<T> *h, HashKey key) {
	MapFindResult fr = {-1, -1, -1};
	if (gb_array_count(h->hashes) > 0) {
		fr.hash_index  = key.key % gb_array_count(h->hashes);
		fr.entry_index = h->hashes[fr.hash_index];
		while (fr.entry_index >= 0) {
			if (hash_key_equal(h->entries[fr.entry_index].key, key)) {
				return fr;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = h->entries[fr.entry_index].next;
		}
	}
	return fr;
}

template <typename T>
gb_internal MapFindResult map__find(Map<T> *h, typename MapEntry<T> *e) {
	MapFindResult fr = {-1, -1, -1};
	if (gb_array_count(h->hashes) > 0) {
		fr.hash_index  = e->key.key % gb_array_count(h->hashes);
		fr.entry_index = h->hashes[fr.hash_index];
		while (fr.entry_index >= 0) {
			if (&h->entries[fr.entry_index] == e) {
				return fr;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = h->entries[fr.entry_index].next;
		}
	}
	return fr;
}


template <typename T>
gb_internal b32 map__full(Map<T> *h) {
	return 0.75f * gb_array_count(h->hashes) <= gb_array_count(h->entries);
}

template <typename T>
gb_inline void map_grow(Map<T> *h) {
	isize new_count = GB_ARRAY_GROW_FORMULA(gb_array_count(h->entries));
	map_rehash(h, new_count);
}

template <typename T>
void map_rehash(Map<T> *h, isize new_count) {
	isize i, j;
	Map<T> nh = {0};
	map_init(&nh, gb_array_allocator(h->hashes));
	gb_array_resize(nh.hashes, new_count);
	gb_array_reserve(nh.entries, gb_array_count(h->entries));
	for (i = 0; i < new_count; i++)
		nh.hashes[i] = -1;
	for (i = 0; i < gb_array_count(h->entries); i++) {
		MapEntry<T> *e = &h->entries[i];
		MapFindResult fr;
		if (gb_array_count(nh.hashes) == 0)
			map_grow(&nh);
		fr = map__find(&nh, e->key);
		j = map__add_entry(&nh, e->key);
		if (fr.entry_prev < 0)
			nh.hashes[fr.hash_index] = j;
		else
			nh.entries[fr.entry_prev].next = j;
		nh.entries[j].next = fr.entry_index;
		nh.entries[j].value = e->value;
		if (map__full(&nh))
			map_grow(&nh);
	}
	map_destroy(h);
	*h = nh;
}

template <typename T>
gb_inline T *map_get(Map<T> *h, HashKey key) {
	isize index = map__find(h, key).entry_index;
	if (index >= 0)
		return &h->entries[index].value;
	return NULL;
}

template <typename T>
void map_set(Map<T> *h, HashKey key, T value) {
	isize index;
	MapFindResult fr;
	if (gb_array_count(h->hashes) == 0)
		map_grow(h);
	fr = map__find(h, key);
	if (fr.entry_index >= 0) {
		index = fr.entry_index;
	} else {
		index = map__add_entry(h, key);
		if (fr.entry_prev >= 0) {
			h->entries[fr.entry_prev].next = index;
		} else {
			h->hashes[fr.hash_index] = index;
		}
	}
	h->entries[index].value = value;

	if (map__full(h))
		map_grow(h);
}



template <typename T>
void map__erase(Map<T> *h, MapFindResult fr) {
	if (fr.entry_prev < 0) {
		h->hashes[fr.hash_index] = h->entries[fr.entry_index].next;
	} else {
		h->entries[fr.entry_prev].next = h->entries[fr.entry_index].next;
	}
	if (fr.entry_index == gb_array_count(h->entries)-1) {
		gb_array_pop(h->entries);
		return;
	}
	h->entries[fr.entry_index] = h->entries[gb_array_count(h->entries)-1];
	MapFindResult last = map__find(h, h->entries[fr.entry_index].key);
	if (last.entry_prev >= 0) {
		h->entries[last.entry_prev].next = fr.entry_index;
	} else {
		h->hashes[last.hash_index] = fr.entry_index;
	}
}

template <typename T>
void map_remove(Map<T> *h, HashKey key) {
	MapFindResult fr = map__find(h, key);
	if (fr.entry_index >= 0) {
		map__erase(h, fr);
	}
}

template <typename T>
gb_inline void map_clear(Map<T> *h) {
	gb_array_clear(h->hashes);
	gb_array_clear(h->entries);
}



template <typename T>
typename MapEntry<T> *multi_map_find_first(Map<T> *h, HashKey key) {
	isize i = map__find(h, key).entry_index;
	if (i < 0) {
		return NULL;
	}
	return &h->entries[i];
}

template <typename T>
typename MapEntry<T> *multi_map_find_next(Map<T> *h, typename MapEntry<T> *e) {
	isize i = e->next;
	while (i >= 0) {
		if (hash_key_equal(h->entries[i].key, e->key)) {
			return &h->entries[i];
		}
		i = h->entries[i].next;
	}
	return NULL;
}

template <typename T>
isize multi_map_count(Map<T> *h, HashKey key) {
	isize count = 0;
	auto *e = multi_map_find_first(h, key);
	while (e != NULL) {
		count++;
		e = multi_map_find_next(h, e);
	}
	return count;
}

template <typename T>
void multi_map_get_all(Map<T> *h, HashKey key, T *items) {
	isize i = 0;
	auto *e = multi_map_find_first(h, key);
	while (e != NULL) {
		items[i++] = e->value;
		e = multi_map_find_next(h, e);
	}
}

template <typename T>
void multi_map_insert(Map<T> *h, HashKey key, T value) {
	if (gb_array_count(h->hashes) == 0) {
		map_grow(h);
	}
	MapFindResult fr = map__find(h, key);
	isize i = map__add_entry(h, key);
	if (fr.entry_prev < 0) {
		h->hashes[fr.hash_index] = i;
	} else {
		h->entries[fr.entry_prev].next = i;
	}
	h->entries[i].next = fr.entry_index;
	h->entries[i].value = value;
	if (map__full(h)) {
		map_grow(h);
	}
}

template <typename T>
void multi_map_remove(Map<T> *h, HashKey key, typename MapEntry<T> *e) {
	MapFindResult fr = map__find(h, e);
	if (fr.entry_index >= 0) {
		map__erase(h, fr);
	}
}

template <typename T>
void multi_map_remove_all(Map<T> *h, HashKey key) {
	while (map_get(h, key) != NULL) {
		map_remove(h, key);
	}
}

