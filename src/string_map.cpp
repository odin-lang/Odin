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
	isize         next;
	T             value;
};

template <typename T>
struct StringMap {
	Slice<isize>              hashes;
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

template <typename T>
gb_inline void string_map_init(StringMap<T> *h, gbAllocator a, isize capacity) {
	capacity = next_pow2_isize(capacity);
	slice_init(&h->hashes,  a, capacity);
	array_init(&h->entries, a, 0, capacity);
	for (isize i = 0; i < capacity; i++) {
		h->hashes.data[i] = -1;
	}
}

template <typename T>
gb_inline void string_map_destroy(StringMap<T> *h) {
	slice_free(&h->hashes, h->entries.allocator);
	array_free(&h->entries);
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
	if (h->hashes.count != 0) {
		fr.hash_index = key.hash & (h->hashes.count-1);
		fr.entry_index = h->hashes.data[fr.hash_index];
		while (fr.entry_index >= 0) {
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
gb_internal StringMapFindResult string_map__find_from_entry(StringMap<T> *h, StringMapEntry<T> *e) {
	StringMapFindResult fr = {-1, -1, -1};
	if (h->hashes.count != 0) {
		fr.hash_index  = e->key.hash & (h->hashes.count-1);
		fr.entry_index = h->hashes.data[fr.hash_index];
		while (fr.entry_index >= 0) {
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
void string_map_rehash(StringMap<T> *h, isize new_count) {
	isize i, j;
	StringMap<T> nh = {};
	new_count = next_pow2_isize(new_count);
	nh.hashes = h->hashes;
	nh.entries.allocator = h->entries.allocator;
	slice_resize(&nh.hashes, h->entries.allocator, new_count);
	for (i = 0; i < new_count; i++) {
		nh.hashes.data[i] = -1;
	}
	array_reserve(&nh.entries, ARRAY_GROW_FORMULA(h->entries.count));
	for (i = 0; i < h->entries.count; i++) {
		StringMapEntry<T> *e = &h->entries.data[i];
		StringMapFindResult fr;
		if (nh.hashes.count == 0) {
			string_map_grow(&nh);
		}
		fr = string_map__find(&nh, e->key);
		j = string_map__add_entry(&nh, e->key);
		if (fr.entry_prev < 0) {
			nh.hashes.data[fr.hash_index] = j;
		} else {
			nh.entries.data[fr.entry_prev].next = j;
		}
		nh.entries.data[j].next = fr.entry_index;
		nh.entries.data[j].value = e->value;
		if (string_map__full(&nh)) {
			string_map_grow(&nh);
		}
	}
	array_free(&h->entries);
	*h = nh;
}

template <typename T>
T *string_map_get(StringMap<T> *h, StringHashKey const &key) {
	isize index = string_map__find(h, key).entry_index;
	if (index >= 0) {
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
	GB_ASSERT(index >= 0);
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
void string_map__erase(StringMap<T> *h, StringMapFindResult const &fr) {
	StringMapFindResult last;
	if (fr.entry_prev < 0) {
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
	if (last.entry_prev >= 0) {
		h->entries.data[last.entry_prev].next = fr.entry_index;
	} else {
		h->hashes.data[last.hash_index] = fr.entry_index;
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
	array_clear(&h->entries);
	for (isize i = 0; i < h->hashes.count; i++) {
		h->hashes.data[i] = -1;
	}
}

