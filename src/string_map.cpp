// NOTE(bill): This util stuff is the same for every `Map`
struct StringMapFindResult {
	isize hash_index;
	isize entry_prev;
	isize entry_index;
};

struct StringHashKey {
	u64    hash;
	String string;
};

StringHashKey string_hashing_proc(void const *data, isize len) {
	StringHashKey h = {};
	h.hash = gb_fnv64a(data, len);
	h.string.text = (u8 *)data;
	h.string.len = len;
	return h;
}

gb_inline StringHashKey string_hash_string(String const &s) {
	return string_hashing_proc(s.text, s.len);
}


bool string_hash_key_equal(StringHashKey a, StringHashKey b) {
	if (a.hash == b.hash) {
		// NOTE(bill): If two string's hashes collide, compare the strings themselves
		return a.string == b.string;
	}
	return false;
}
bool operator==(StringHashKey a, StringHashKey b) { return string_hash_key_equal(a, b); }
bool operator!=(StringHashKey a, StringHashKey b) { return !string_hash_key_equal(a, b); }

template <typename T>
struct StringMapEntry {
	StringHashKey key;
	isize         next;
	T             value;
};

template <typename T>
struct StringMap {
	Array<isize>              hashes;
	Array<StringMapEntry<T> > entries;
};


template <typename T> void string_map_init             (StringMap<T> *h, gbAllocator a, isize capacity = 16);
template <typename T> void string_map_destroy          (StringMap<T> *h);

template <typename T> T *  string_map_get              (StringMap<T> *h, char const *key);
template <typename T> T *  string_map_get              (StringMap<T> *h, String const &key);
template <typename T> T *  string_map_get              (StringMap<T> *h, StringHashKey const &key);

template <typename T> void string_map_set              (StringMap<T> *h, StringHashKey const &key, T const &value);
template <typename T> void string_map_set              (StringMap<T> *h, String const &key, T const &value);
template <typename T> void string_map_set              (StringMap<T> *h, char const *key,   T const &value);

template <typename T> void string_map_remove           (StringMap<T> *h, StringHashKey const &key);
template <typename T> void string_map_clear            (StringMap<T> *h);
template <typename T> void string_map_grow             (StringMap<T> *h);
template <typename T> void string_map_rehash           (StringMap<T> *h, isize new_count);

template <typename T>
gb_inline void string_map_init(StringMap<T> *h, gbAllocator a, isize capacity) {
	array_init(&h->hashes,  a, capacity);
	array_init(&h->entries, a, 0, capacity);
	for (isize i = 0; i < capacity; i++) {
		h->hashes.data[i] = -1;
	}
}

template <typename T>
gb_inline void string_map_destroy(StringMap<T> *h) {
	array_free(&h->entries);
	array_free(&h->hashes);
}

template <typename T>
gb_internal isize string_map__add_entry(StringMap<T> *h, StringHashKey const &key) {
	StringMapEntry<T> e = {};
	e.key = key;
	e.next = -1;
	array_add(&h->entries, e);
	return h->entries.count-1;
}

template <typename T>
gb_internal StringMapFindResult string_map__find(StringMap<T> *h, StringHashKey const &key) {
	StringMapFindResult fr = {-1, -1, -1};
	if (h->hashes.count > 0) {
		fr.hash_index = key.hash % h->hashes.count;
		fr.entry_index = h->hashes[fr.hash_index];
		while (fr.entry_index >= 0) {
			if (string_hash_key_equal(h->entries[fr.entry_index].key, key)) {
				return fr;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = h->entries[fr.entry_index].next;
		}
	}
	return fr;
}

template <typename T>
gb_internal StringMapFindResult string_map__find_from_entry(StringMap<T> *h, StringMapEntry<T> *e) {
	StringMapFindResult fr = {-1, -1, -1};
	if (h->hashes.count > 0) {
		fr.hash_index  = e->key.hash % h->hashes.count;
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
gb_internal b32 string_map__full(StringMap<T> *h) {
	return 0.75f * h->hashes.count <= h->entries.count;
}

#define STRING_MAP_ARRAY_GROW_FORMULA(x) (4*(x) + 7)
GB_STATIC_ASSERT(STRING_MAP_ARRAY_GROW_FORMULA(0) > 0);

template <typename T>
gb_inline void string_map_grow(StringMap<T> *h) {
	isize new_count = STRING_MAP_ARRAY_GROW_FORMULA(h->entries.count);
	string_map_rehash(h, new_count);
}

template <typename T>
void string_map_rehash(StringMap<T> *h, isize new_count) {
	isize i, j;
	StringMap<T> nh = {};
	string_map_init(&nh, h->hashes.allocator, new_count);
	array_resize(&nh.hashes, new_count);
	array_reserve(&nh.entries, h->entries.count);
	for (i = 0; i < new_count; i++) {
		nh.hashes[i] = -1;
	}
	for (i = 0; i < h->entries.count; i++) {
		StringMapEntry<T> *e = &h->entries[i];
		StringMapFindResult fr;
		if (nh.hashes.count == 0) {
			string_map_grow(&nh);
		}
		fr = string_map__find(&nh, e->key);
		j = string_map__add_entry(&nh, e->key);
		if (fr.entry_prev < 0) {
			nh.hashes[fr.hash_index] = j;
		} else {
			nh.entries[fr.entry_prev].next = j;
		}
		nh.entries[j].next = fr.entry_index;
		nh.entries[j].value = e->value;
		if (string_map__full(&nh)) {
			string_map_grow(&nh);
		}
	}
	string_map_destroy(h);
	*h = nh;
}

template <typename T>
T *string_map_get(StringMap<T> *h, StringHashKey const &key) {
	isize index = string_map__find(h, key).entry_index;
	if (index >= 0) {
		return &h->entries[index].value;
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
void string_map_set(StringMap<T> *h, StringHashKey const &key, T const &value) {
	isize index;
	StringMapFindResult fr;
	if (h->hashes.count == 0) {
		string_map_grow(h);
	}
	fr = string_map__find(h, key);
	if (fr.entry_index >= 0) {
		index = fr.entry_index;
	} else {
		index = string_map__add_entry(h, key);
		if (fr.entry_prev >= 0) {
			h->entries[fr.entry_prev].next = index;
		} else {
			h->hashes[fr.hash_index] = index;
		}
	}
	h->entries[index].value = value;

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
void string_map__erase(StringMap<T> *h, StringMapFindResult const &fr) {
	StringMapFindResult last;
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
	last = string_map__find(h, h->entries[fr.entry_index].key);
	if (last.entry_prev >= 0) {
		h->entries[last.entry_prev].next = fr.entry_index;
	} else {
		h->hashes[last.hash_index] = fr.entry_index;
	}
}

template <typename T>
void string_map_remove(StringMap<T> *h, StringHashKey const &key) {
	StringMapFindResult fr = string_map__find(h, key);
	if (fr.entry_index >= 0) {
		string_map__erase(h, fr);
	}
}

template <typename T>
gb_inline void string_map_clear(StringMap<T> *h) {
	array_clear(&h->hashes);
	array_clear(&h->entries);
}

