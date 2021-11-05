struct StringHashKey {
	u32    hash;
	String string;
};

gb_inline StringHashKey string_hash_string(String const &s) {
	StringHashKey hash_key = {};
	hash_key.hash = fnv32a(s.text, s.len);
	hash_key.string = s;
	return hash_key;
}


bool string_hash_key_equal(StringHashKey const &a, StringHashKey const &b) {
	if (a.hash == b.hash) {
		// NOTE(bill): If two string's hashes collide, compare the strings themselves
		return a.string == b.string;
	}
	return false;
}
bool operator==(StringHashKey const &a, StringHashKey const &b) { return string_hash_key_equal(a, b); }
bool operator!=(StringHashKey const &a, StringHashKey const &b) { return !string_hash_key_equal(a, b); }

template <typename T>
struct StringMapEntry {
	StringHashKey key;
	MapIndex      next;
	T             value;
};

template <typename T>
struct StringMap {
	Slice<MapIndex>           hashes;
	Array<StringMapEntry<T> > entries;
};


template <typename T> void string_map_init             (StringMap<T> *h, gbAllocator a, isize capacity = 16);
template <typename T> void string_map_destroy          (StringMap<T> *h);

template <typename T> T *  string_map_get              (StringMap<T> *h, char const *key);
template <typename T> T *  string_map_get              (StringMap<T> *h, String const &key);
template <typename T> T *  string_map_get              (StringMap<T> *h, StringHashKey const &key);

template <typename T> T &  string_map_must_get         (StringMap<T> *h, char const *key);
template <typename T> T &  string_map_must_get         (StringMap<T> *h, String const &key);
template <typename T> T &  string_map_must_get         (StringMap<T> *h, StringHashKey const &key);

template <typename T> void string_map_set              (StringMap<T> *h, StringHashKey const &key, T const &value);
template <typename T> void string_map_set              (StringMap<T> *h, String const &key, T const &value);
template <typename T> void string_map_set              (StringMap<T> *h, char const *key,   T const &value);

template <typename T> void string_map_remove           (StringMap<T> *h, StringHashKey const &key);
template <typename T> void string_map_clear            (StringMap<T> *h);
template <typename T> void string_map_grow             (StringMap<T> *h);
template <typename T> void string_map_rehash           (StringMap<T> *h, isize new_count);
template <typename T> void string_map_reserve          (StringMap<T> *h, isize cap);

template <typename T>
gb_inline void string_map_init(StringMap<T> *h, gbAllocator a, isize capacity) {
	capacity = next_pow2_isize(capacity);
	slice_init(&h->hashes,  a, capacity);
	array_init(&h->entries, a, 0, capacity);
	for (isize i = 0; i < capacity; i++) {
		h->hashes.data[i] = MAP_SENTINEL;
	}
}

template <typename T>
gb_inline void string_map_destroy(StringMap<T> *h) {
	slice_free(&h->hashes, h->entries.allocator);
	array_free(&h->entries);
}

template <typename T>
gb_internal MapIndex string_map__add_entry(StringMap<T> *h, StringHashKey const &key) {
	StringMapEntry<T> e = {};
	e.key = key;
	e.next = MAP_SENTINEL;
	array_add(&h->entries, e);
	return cast(MapIndex)(h->entries.count-1);
}

template <typename T>
gb_internal MapFindResult string_map__find(StringMap<T> *h, StringHashKey const &key) {
	MapFindResult fr = {MAP_SENTINEL, MAP_SENTINEL, MAP_SENTINEL};
	if (h->hashes.count != 0) {
		fr.hash_index = cast(MapIndex)(key.hash & (h->hashes.count-1));
		fr.entry_index = h->hashes.data[fr.hash_index];
		while (fr.entry_index != MAP_SENTINEL) {
			if (string_hash_key_equal(h->entries.data[fr.entry_index].key, key)) {
				return fr;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = h->entries.data[fr.entry_index].next;
		}
	}
	return fr;
}

template <typename T>
gb_internal MapFindResult string_map__find_from_entry(StringMap<T> *h, StringMapEntry<T> *e) {
	MapFindResult fr = {MAP_SENTINEL, MAP_SENTINEL, MAP_SENTINEL};
	if (h->hashes.count != 0) {
		fr.hash_index  = cast(MapIndex)(e->key.hash & (h->hashes.count-1));
		fr.entry_index = h->hashes.data[fr.hash_index];
		while (fr.entry_index != MAP_SENTINEL) {
			if (&h->entries.data[fr.entry_index] == e) {
				return fr;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = h->entries.data[fr.entry_index].next;
		}
	}
	return fr;
}

template <typename T>
gb_internal b32 string_map__full(StringMap<T> *h) {
	return 0.75f * h->hashes.count <= h->entries.count;
}

template <typename T>
gb_inline void string_map_grow(StringMap<T> *h) {
	isize new_count = gb_max(h->hashes.count<<1, 16);
	string_map_rehash(h, new_count);
}


template <typename T>
void string_map_reset_entries(StringMap<T> *h) {
	for (isize i = 0; i < h->hashes.count; i++) {
		h->hashes.data[i] = MAP_SENTINEL;
	}
	for (isize i = 0; i < h->entries.count; i++) {
		MapFindResult fr;
		StringMapEntry<T> *e = &h->entries.data[i];
		e->next = MAP_SENTINEL;
		fr = string_map__find_from_entry(h, e);
		if (fr.entry_prev == MAP_SENTINEL) {
			h->hashes[fr.hash_index] = cast(MapIndex)i;
		} else {
			h->entries[fr.entry_prev].next = cast(MapIndex)i;
		}
	}
}

template <typename T>
void string_map_reserve(StringMap<T> *h, isize cap) {
	array_reserve(&h->entries, cap);
	if (h->entries.count*2 < h->hashes.count) {
		return;
	}
	slice_resize(&h->hashes, h->entries.allocator, cap*2);
	string_map_reset_entries(h);
}


template <typename T>
void string_map_rehash(StringMap<T> *h, isize new_count) {
	string_map_reserve(h, new_count);
}

template <typename T>
T *string_map_get(StringMap<T> *h, StringHashKey const &key) {
	isize index = string_map__find(h, key).entry_index;
	if (index != MAP_SENTINEL) {
		return &h->entries.data[index].value;
	}
	return nullptr;
}

template <typename T>
gb_inline T *string_map_get(StringMap<T> *h, String const &key) {
	return string_map_get(h, string_hash_string(key));
}

template <typename T>
gb_inline T *string_map_get(StringMap<T> *h, char const *key) {
	return string_map_get(h, string_hash_string(make_string_c(key)));
}

template <typename T>
T &string_map_must_get(StringMap<T> *h, StringHashKey const &key) {
	isize index = string_map__find(h, key).entry_index;
	GB_ASSERT(index != MAP_SENTINEL);
	return h->entries.data[index].value;
}

template <typename T>
gb_inline T &string_map_must_get(StringMap<T> *h, String const &key) {
	return string_map_must_get(h, string_hash_string(key));
}

template <typename T>
gb_inline T &string_map_must_get(StringMap<T> *h, char const *key) {
	return string_map_must_get(h, string_hash_string(make_string_c(key)));
}

template <typename T>
void string_map_set(StringMap<T> *h, StringHashKey const &key, T const &value) {
	MapIndex index;
	MapFindResult fr;
	if (h->hashes.count == 0) {
		string_map_grow(h);
	}
	fr = string_map__find(h, key);
	if (fr.entry_index != MAP_SENTINEL) {
		index = fr.entry_index;
	} else {
		index = string_map__add_entry(h, key);
		if (fr.entry_prev != MAP_SENTINEL) {
			h->entries.data[fr.entry_prev].next = index;
		} else {
			h->hashes.data[fr.hash_index] = index;
		}
	}
	h->entries.data[index].value = value;

	if (string_map__full(h)) {
		string_map_grow(h);
	}
}

template <typename T>
gb_inline void string_map_set(StringMap<T> *h, String const &key, T const &value) {
	string_map_set(h, string_hash_string(key), value);
}

template <typename T>
gb_inline void string_map_set(StringMap<T> *h, char const *key, T const &value) {
	string_map_set(h, string_hash_string(make_string_c(key)), value);
}


template <typename T>
void string_map__erase(StringMap<T> *h, MapFindResult const &fr) {
	MapFindResult last;
	if (fr.entry_prev == MAP_SENTINEL) {
		h->hashes.data[fr.hash_index] = h->entries.data[fr.entry_index].next;
	} else {
		h->entries.data[fr.entry_prev].next = h->entries.data[fr.entry_index].next;
	}
	if (fr.entry_index == h->entries.count-1) {
		array_pop(&h->entries);
		return;
	}
	h->entries.data[fr.entry_index] = h->entries.data[h->entries.count-1];
	last = string_map__find(h, h->entries.data[fr.entry_index].key);
	if (last.entry_prev != MAP_SENTINEL) {
		h->entries.data[last.entry_prev].next = fr.entry_index;
	} else {
		h->hashes.data[last.hash_index] = fr.entry_index;
	}
}

template <typename T>
void string_map_remove(StringMap<T> *h, StringHashKey const &key) {
	MapFindResult fr = string_map__find(h, key);
	if (fr.entry_index != MAP_SENTINEL) {
		string_map__erase(h, fr);
	}
}

template <typename T>
gb_inline void string_map_clear(StringMap<T> *h) {
	array_clear(&h->entries);
	for (isize i = 0; i < h->hashes.count; i++) {
		h->hashes.data[i] = MAP_SENTINEL;
	}
}

