#define GB_NO_WINDOWS_H
#define GB_IMPLEMENTATION
#include "gb/gb.h"

#include "string.cpp"

// Hasing

struct HashKey {
	u64 key;
	b32 is_string;
	String string; // if String, s.len > 0
};

gb_inline HashKey hashing_proc(void const *data, isize len) {
	HashKey h = {};
	h.key = gb_murmur64(data, len);
	// h.key = gb_fnv64a(data, len);
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
			if (b.is_string) return are_strings_equal(a.string, b.string);
			return false;
		}
		return true;
	}
	return false;
}

i64 next_pow2(i64 n) {
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
void map_remove(Map<T> *h, HashKey key) {
	MapFindResult fr = map__find(h, key);
	if (fr.entry_index >= 0) {
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
}

template <typename T>
gb_inline void map_clear(Map<T> *h) {
	gb_array_clear(h->hashes);
	gb_array_clear(h->entries);
}
