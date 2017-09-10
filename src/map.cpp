// A `Map` is an unordered hash table which can allow for a key to point to multiple values
// with the use of the `multi_*` procedures.
// TODO(bill): I should probably allow the `multi_map_*` stuff to be #ifdefed out

#ifndef MAP_UTIL_STUFF
#define MAP_UTIL_STUFF
// NOTE(bill): This util stuff is the same for every `Map`
struct MapFindResult {
	isize hash_index;
	isize entry_prev;
	isize entry_index;
};

enum HashKeyKind {
	HashKey_Default,
	HashKey_String,
	HashKey_Ptr,
	HashKey_PtrAndId,
};

struct PtrAndId {
	void *ptr;
	u32   id;
};

struct HashKey {
	HashKeyKind kind;
	// u128        key;
	u64         key;
	union {
		String       string; // if String, s.len > 0
		void *       ptr;
		PtrAndId ptr_and_id;
	};
};

gb_inline HashKey hashing_proc(void const *data, isize len) {
	HashKey h = {HashKey_Default};
	h.kind = HashKey_Default;
	// h.key = u128_from_u64(gb_fnv64a(data, len));
	h.key = gb_fnv64a(data, len);

	return h;
}

gb_inline HashKey hash_string(String s) {
	HashKey h = hashing_proc(s.text, s.len);
	h.kind = HashKey_String;
	h.string = s;
	return h;
}

gb_inline HashKey hash_pointer(void *ptr) {
	HashKey h = {HashKey_Ptr};
	h.key = cast(u64)cast(uintptr)ptr;
	h.ptr = ptr;
	return h;
}
gb_inline HashKey hash_ptr_and_id(void *ptr, u32 id) {
	HashKey h = {HashKey_PtrAndId};
	h.key = cast(u64)cast(uintptr)ptr;
	h.ptr_and_id.ptr = ptr;
	h.ptr_and_id.id  = id;
	return h;
}

bool hash_key_equal(HashKey a, HashKey b) {
	if (a.key == b.key) {
		// NOTE(bill): If two string's hashes collide, compare the strings themselves
		if (a.kind == HashKey_String) {
			if (b.kind == HashKey_String) {
				return a.string == b.string;
			}
			return false;
		} else if (a.kind == HashKey_PtrAndId) {
			if (b.kind == HashKey_PtrAndId) {
				return a.ptr_and_id.id == b.ptr_and_id.id;
			}
			return false;
		}
		return true;
	}
	return false;
}
bool operator==(HashKey a, HashKey b) { return hash_key_equal(a, b); }
bool operator!=(HashKey a, HashKey b) { return !hash_key_equal(a, b); }

#endif

template <typename T>
struct MapEntry {
	HashKey  key;
	isize    next;
	T        value;
};

template <typename T>
struct Map {
	Array<isize>        hashes;
	Array<MapEntry<T> > entries;
};


template <typename T> void map_init             (Map<T> *h, gbAllocator a, isize capacity = 16);
template <typename T> void map_destroy          (Map<T> *h);
template <typename T> T *  map_get              (Map<T> *h, HashKey key);
template <typename T> void map_set              (Map<T> *h, HashKey key, T const &value);
template <typename T> void map_remove           (Map<T> *h, HashKey key);
template <typename T> void map_clear            (Map<T> *h);
template <typename T> void map_grow             (Map<T> *h);
template <typename T> void map_rehash           (Map<T> *h, isize new_count);

// Mutlivalued map procedure
template <typename T> MapEntry<T> * multi_map_find_first(Map<T> *h, HashKey key);
template <typename T> MapEntry<T> * multi_map_find_next (Map<T> *h, MapEntry<T> *e);

template <typename T> isize multi_map_count     (Map<T> *h, HashKey key);
template <typename T> void  multi_map_get_all   (Map<T> *h, HashKey key, T *items);
template <typename T> void  multi_map_insert    (Map<T> *h, HashKey key, T const &value);
template <typename T> void  multi_map_remove    (Map<T> *h, HashKey key, MapEntry<T> *e);
template <typename T> void  multi_map_remove_all(Map<T> *h, HashKey key);


template <typename T>
gb_inline void map_init(Map<T> *h, gbAllocator a, isize capacity) {
	array_init(&h->hashes,  a, capacity);
	array_init(&h->entries, a, capacity);
}

template <typename T>
gb_inline void map_destroy(Map<T> *h) {
	array_free(&h->entries);
	array_free(&h->hashes);
}

template <typename T>
gb_internal isize map__add_entry(Map<T> *h, HashKey key) {
	MapEntry<T> e = {};
	e.key = key;
	e.next = -1;
	array_add(&h->entries, e);
	return h->entries.count-1;
}

template <typename T>
gb_internal MapFindResult map__find(Map<T> *h, HashKey key) {
	MapFindResult fr = {-1, -1, -1};
	if (h->hashes.count > 0) {
		// fr.hash_index  = u128_to_i64(key.key % u128_from_i64(h->hashes.count));
		fr.hash_index = key.key % h->hashes.count;
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
gb_internal MapFindResult map__find_from_entry(Map<T> *h, MapEntry<T> *e) {
	MapFindResult fr = {-1, -1, -1};
	if (h->hashes.count > 0) {
		fr.hash_index  = e->key.key % h->hashes.count;
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
	return 0.75f * h->hashes.count <= h->entries.count;
}

template <typename T>
gb_inline void map_grow(Map<T> *h) {
	isize new_count = ARRAY_GROW_FORMULA(h->entries.count);
	map_rehash(h, new_count);
}

template <typename T>
void map_rehash(Map<T> *h, isize new_count) {
	isize i, j;
	Map<T> nh = {};
	map_init(&nh, h->hashes.allocator);
	array_resize(&nh.hashes, new_count);
	array_reserve(&nh.entries, h->entries.count);
	for (i = 0; i < new_count; i++) {
		nh.hashes[i] = -1;
	}
	for (i = 0; i < h->entries.count; i++) {
		MapEntry<T> *e = &h->entries[i];
		MapFindResult fr;
		if (nh.hashes.count == 0) {
			map_grow(&nh);
		}
		fr = map__find(&nh, e->key);
		j = map__add_entry(&nh, e->key);
		if (fr.entry_prev < 0) {
			nh.hashes[fr.hash_index] = j;
		} else {
			nh.entries[fr.entry_prev].next = j;
		}
		nh.entries[j].next = fr.entry_index;
		nh.entries[j].value = e->value;
		if (map__full(&nh)) {
			map_grow(&nh);
		}
	}
	map_destroy(h);
	*h = nh;
}

template <typename T>
gb_inline T *map_get(Map<T> *h, HashKey key) {
	isize index = map__find(h, key).entry_index;
	if (index >= 0) {
		return &h->entries[index].value;
	}
	return nullptr;
}

template <typename T>
void map_set(Map<T> *h, HashKey key, T const &value) {
	isize index;
	MapFindResult fr;
	if (h->hashes.count == 0)
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

	if (map__full(h)) {
		map_grow(h);
	}
}


template <typename T>
void map__erase(Map<T> *h, MapFindResult fr) {
	MapFindResult last;
	if (fr.entry_prev < 0) {
		h->hashes[fr.hash_index] = h->entries[fr.entry_index].next;
	} else {
		h->entries[fr.entry_prev].next = h->entries[fr.entry_index].next;
	}
	if (fr.entry_index == h->entries.count-1) {
		array_pop(&h->entries);
		return;
	}
	h->entries[fr.entry_index] = h->entries[h->entries.count-1];
	last = map__find(h, h->entries[fr.entry_index].key);
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
	array_clear(&h->hashes);
	array_clear(&h->entries);
}


#if 1
template <typename T>
MapEntry<T> *multi_map_find_first(Map<T> *h, HashKey key) {
	isize i = map__find(h, key).entry_index;
	if (i < 0) {
		return nullptr;
	}
	return &h->entries[i];
}

template <typename T>
MapEntry<T> *multi_map_find_next(Map<T> *h, MapEntry<T> *e) {
	isize i = e->next;
	while (i >= 0) {
		if (hash_key_equal(h->entries[i].key, e->key)) {
			return &h->entries[i];
		}
		i = h->entries[i].next;
	}
	return nullptr;
}

template <typename T>
isize multi_map_count(Map<T> *h, HashKey key) {
	isize count = 0;
	MapEntry<T> *e = multi_map_find_first(h, key);
	while (e != nullptr) {
		count++;
		e = multi_map_find_next(h, e);
	}
	return count;
}

template <typename T>
void multi_map_get_all(Map<T> *h, HashKey key, T *items) {
	isize i = 0;
	MapEntry<T> *e = multi_map_find_first(h, key);
	while (e != nullptr) {
		items[i++] = e->value;
		e = multi_map_find_next(h, e);
	}
}

template <typename T>
void multi_map_insert(Map<T> *h, HashKey key, T const &value) {
	MapFindResult fr;
	isize i;
	if (h->hashes.count == 0) {
		map_grow(h);
	}
	// Make
	fr = map__find(h, key);
	i = map__add_entry(h, key);
	if (fr.entry_prev < 0) {
		h->hashes[fr.hash_index] = i;
	} else {
		h->entries[fr.entry_prev].next = i;
	}
	h->entries[i].next = fr.entry_index;
	h->entries[i].value = value;
	// Grow if needed
	if (map__full(h)) {
		map_grow(h);
	}
}

template <typename T>
void multi_map_remove(Map<T> *h, HashKey key, MapEntry<T> *e) {
	MapFindResult fr = map__find_from_entry(h, e);
	if (fr.entry_index >= 0) {
		map__erase(h, fr);
	}
}

template <typename T>
void multi_map_remove_all(Map<T> *h, HashKey key) {
	while (map_get(h, key) != nullptr) {
		map_remove(h, key);
	}
}
#endif
