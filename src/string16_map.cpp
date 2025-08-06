GB_STATIC_ASSERT(sizeof(MapIndex) == sizeof(u32));


struct String16HashKey {
	String16 string;
	u32      hash;

	operator String16() const noexcept {
		return this->string;
	}
	operator String16 const &() const noexcept {
		return this->string;
	}
};
gb_internal gb_inline u32 string_hash(String16 const &s) {
	u32 res = fnv32a(s.text, s.len*gb_size_of(u16)) & 0x7fffffff;
	return res | (res == 0);
}

gb_internal gb_inline String16HashKey string_hash_string(String16 const &s) {
	String16HashKey hash_key = {};
	hash_key.hash = string_hash(s);
	hash_key.string = s;
	return hash_key;
}


#if 1 /* old string map */

template <typename T>
struct String16MapEntry {
	String16      key;
	u32           hash;
	MapIndex      next;
	T             value;
};

template <typename T>
struct String16Map {
	MapIndex *           hashes;
	usize                hashes_count;
	String16MapEntry<T> *entries;
	u32                  count;
	u32                  entries_capacity;
};


template <typename T> gb_internal void string16_map_init    (String16Map<T> *h, usize capacity = 16);
template <typename T> gb_internal void string16_map_destroy (String16Map<T> *h);

template <typename T> gb_internal T *  string16_map_get     (String16Map<T> *h, String16HashKey const &key);
template <typename T> gb_internal T &  string16_map_must_get(String16Map<T> *h, String16HashKey const &key);
template <typename T> gb_internal void string16_map_set     (String16Map<T> *h, String16HashKey const &key, T const &value);

// template <typename T> gb_internal void string16_map_remove  (String16Map<T> *h, String16HashKey const &key);
template <typename T> gb_internal void string16_map_clear   (String16Map<T> *h);
template <typename T> gb_internal void string16_map_grow    (String16Map<T> *h);
template <typename T> gb_internal void string16_map_reserve (String16Map<T> *h, usize new_count);

gb_internal gbAllocator string16_map_allocator(void) {
	return heap_allocator();
}

template <typename T>
gb_internal gb_inline void string16_map_init(String16Map<T> *h, usize capacity) {
	capacity = next_pow2_isize(capacity);
	string16_map_reserve(h, capacity);
}

template <typename T>
gb_internal gb_inline void string16_map_destroy(String16Map<T> *h) {
	gb_free(string16_map_allocator(), h->hashes);
	gb_free(string16_map_allocator(), h->entries);
}


template <typename T>
gb_internal void string16_map__resize_hashes(String16Map<T> *h, usize count) {
	h->hashes_count = cast(u32)resize_array_raw(&h->hashes, string16_map_allocator(), h->hashes_count, count, MAP_CACHE_LINE_SIZE);
}


template <typename T>
gb_internal void string16_map__reserve_entries(String16Map<T> *h, usize capacity) {
	h->entries_capacity = cast(u32)resize_array_raw(&h->entries, string16_map_allocator(), h->entries_capacity, capacity, MAP_CACHE_LINE_SIZE);
}


template <typename T>
gb_internal MapIndex string16_map__add_entry(String16Map<T> *h, u32 hash, String16 const &key) {
	String16MapEntry<T> e = {};
	e.key = key;
	e.hash = hash;
	e.next = MAP_SENTINEL;
	if (h->count+1 >= h->entries_capacity) {
		string16_map__reserve_entries(h, gb_max(h->entries_capacity*2, 4));
	}
	h->entries[h->count++] = e;
	return cast(MapIndex)(h->count-1);
}

template <typename T>
gb_internal MapFindResult string16_map__find(String16Map<T> *h, u32 hash, String16 const &key) {
	MapFindResult fr = {MAP_SENTINEL, MAP_SENTINEL, MAP_SENTINEL};
	if (h->hashes_count != 0) {
		fr.hash_index = cast(MapIndex)(hash & (h->hashes_count-1));
		fr.entry_index = h->hashes[fr.hash_index];
		while (fr.entry_index != MAP_SENTINEL) {
			auto *entry = &h->entries[fr.entry_index];
			if (entry->hash == hash && entry->key == key) {
				return fr;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = entry->next;
		}
	}
	return fr;
}

template <typename T>
gb_internal MapFindResult string16_map__find_from_entry(String16Map<T> *h, String16MapEntry<T> *e) {
	MapFindResult fr = {MAP_SENTINEL, MAP_SENTINEL, MAP_SENTINEL};
	if (h->hashes_count != 0) {
		fr.hash_index  = cast(MapIndex)(e->hash & (h->hashes_count-1));
		fr.entry_index = h->hashes[fr.hash_index];
		while (fr.entry_index != MAP_SENTINEL) {
			auto *entry = &h->entries[fr.entry_index];
			if (entry == e) {
				return fr;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = entry->next;
		}
	}
	return fr;
}

template <typename T>
gb_internal b32 string16_map__full(String16Map<T> *h) {
	return 0.75f * h->hashes_count <= h->count;
}

template <typename T>
gb_inline void string16_map_grow(String16Map<T> *h) {
	isize new_count = gb_max(h->hashes_count<<1, 16);
	string16_map_reserve(h, new_count);
}


template <typename T>
gb_internal void string16_map_reset_entries(String16Map<T> *h) {
	for (u32 i = 0; i < h->hashes_count; i++) {
		h->hashes[i] = MAP_SENTINEL;
	}
	for (isize i = 0; i < h->count; i++) {
		MapFindResult fr;
		String16MapEntry<T> *e = &h->entries[i];
		e->next = MAP_SENTINEL;
		fr = string16_map__find_from_entry(h, e);
		if (fr.entry_prev == MAP_SENTINEL) {
			h->hashes[fr.hash_index] = cast(MapIndex)i;
		} else {
			h->entries[fr.entry_prev].next = cast(MapIndex)i;
		}
	}
}

template <typename T>
gb_internal void string16_map_reserve(String16Map<T> *h, usize cap) {
	if (h->count*2 < h->hashes_count) {
		return;
	}
	string16_map__reserve_entries(h, cap);
	string16_map__resize_hashes(h,   cap*2);
	string16_map_reset_entries(h);
}

template <typename T>
gb_internal T *string16_map_get(String16Map<T> *h, u32 hash, String16 const &key) {
	MapFindResult fr = {MAP_SENTINEL, MAP_SENTINEL, MAP_SENTINEL};
	if (h->hashes_count != 0) {
		fr.hash_index = cast(MapIndex)(hash & (h->hashes_count-1));
		fr.entry_index = h->hashes[fr.hash_index];
		while (fr.entry_index != MAP_SENTINEL) {
			auto *entry = &h->entries[fr.entry_index];
			if (entry->hash == hash && entry->key == key) {
				return &entry->value;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = entry->next;
		}
	}
	return nullptr;
}


template <typename T>
gb_internal gb_inline T *string16_map_get(String16Map<T> *h, String16HashKey const &key) {
	return string16_map_get(h, key.hash, key.string);
}
template <typename T>
gb_internal T &string16_map_must_get(String16Map<T> *h, u32 hash, String16 const &key) {
	isize index = string16_map__find(h, hash, key).entry_index;
	GB_ASSERT(index != MAP_SENTINEL);
	return h->entries[index].value;
}

template <typename T>
gb_internal T &string16_map_must_get(String16Map<T> *h, String16HashKey const &key) {
	return string16_map_must_get(h, key.hash, key.string);
}

template <typename T>
gb_internal void string16_map_set(String16Map<T> *h, u32 hash, String16 const &key, T const &value) {
	MapIndex index;
	MapFindResult fr;
	if (h->hashes_count == 0) {
		string16_map_grow(h);
	}
	fr = string16_map__find(h, hash, key);
	if (fr.entry_index != MAP_SENTINEL) {
		index = fr.entry_index;
	} else {
		index = string16_map__add_entry(h, hash, key);
		if (fr.entry_prev != MAP_SENTINEL) {
			h->entries[fr.entry_prev].next = index;
		} else {
			h->hashes[fr.hash_index] = index;
		}
	}
	h->entries[index].value = value;

	if (string16_map__full(h)) {
		string16_map_grow(h);
	}
}

template <typename T>
gb_internal gb_inline void string16_map_set(String16Map<T> *h, String16HashKey const &key, T const &value) {
	string16_map_set(h, key.hash, key.string, value);
}


template <typename T>
gb_internal gb_inline void string16_map_clear(String16Map<T> *h) {
	h->count = 0;
	for (u32 i = 0; i < h->hashes_count; i++) {
		h->hashes[i] = MAP_SENTINEL;
	}
}



template <typename T>
gb_internal String16MapEntry<T> *begin(String16Map<T> &m) noexcept {
	return m.entries;
}
template <typename T>
gb_internal String16MapEntry<T> const *begin(String16Map<T> const &m) noexcept {
	return m.entries;
}


template <typename T>
gb_internal String16MapEntry<T> *end(String16Map<T> &m) noexcept {
	return m.entries + m.count;
}

template <typename T>
gb_internal String16MapEntry<T> const *end(String16Map<T> const &m) noexcept {
	return m.entries + m.count;
}

#else /* new string map */

template <typename T>
struct StringMapEntry {
	String key;
	u32    hash;
	T      value;
};

template <typename T>
struct StringMap {
	String16MapEntry<T> *entries;
	u32                count;
	u32                capacity;
};


template <typename T> gb_internal void string16_map_init    (String16Map<T> *h, usize capacity = 16);
template <typename T> gb_internal void string16_map_destroy (String16Map<T> *h);

template <typename T> gb_internal T *  string16_map_get     (String16Map<T> *h, String16 const &key);
template <typename T> gb_internal T *  string16_map_get     (String16Map<T> *h, String16HashKey const &key);

template <typename T> gb_internal T &  string16_map_must_get(String16Map<T> *h, String16 const &key);
template <typename T> gb_internal T &  string16_map_must_get(String16Map<T> *h, String16HashKey const &key);

template <typename T> gb_internal void string16_map_set     (String16Map<T> *h, String16 const &key, T const &value);
template <typename T> gb_internal void string16_map_set     (String16Map<T> *h, String16HashKey const &key, T const &value);

// template <typename T> gb_internal void string16_map_remove  (String16Map<T> *h, String16HashKey const &key);
template <typename T> gb_internal void string16_map_clear   (String16Map<T> *h);
template <typename T> gb_internal void string16_map_grow    (String16Map<T> *h);
template <typename T> gb_internal void string16_map_reserve (String16Map<T> *h, usize new_count);

gb_internal gbAllocator string16_map_allocator(void) {
	return heap_allocator();
}

template <typename T>
gb_internal gb_inline void string16_map_init(String16Map<T> *h, usize capacity) {
	capacity = next_pow2_isize(capacity);
	string16_map_reserve(h, capacity);
}

template <typename T>
gb_internal gb_inline void string16_map_destroy(String16Map<T> *h) {
	gb_free(string16_map_allocator(), h->entries);
}


template <typename T>
gb_internal void string16_map__insert(String16Map<T> *h, u32 hash, String16 const &key, T const &value) {
	if (h->count+1 >= h->capacity) {
		string16_map_grow(h);
	}
	GB_ASSERT(h->count+1 < h->capacity);

	u32 mask = h->capacity-1;
	MapIndex index = hash & mask;
	MapIndex original_index = index;
	do {
		auto *entry = h->entries+index;
		if (entry->hash == 0) {
			entry->key   = key;
			entry->hash  = hash;
			entry->value = value;

			h->count += 1;
			return;
		}
		index = (index+1)&mask;
	} while (index != original_index);

	GB_PANIC("Full map");
}

template <typename T>
gb_internal b32 string16_map__full(String16Map<T> *h) {
	return 0.75f * h->count <= h->capacity;
}

template <typename T>
gb_inline void string16_map_grow(String16Map<T> *h) {
	isize new_capacity = gb_max(h->capacity<<1, 16);
	string16_map_reserve(h, new_capacity);
}


template <typename T>
gb_internal void string16_map_reserve(String16Map<T> *h, usize cap) {
	if (cap < h->capacity) {
		return;
	}
	cap = next_pow2_isize(cap);

	String16Map<T> new_h = {};
	new_h.count    = 0;
	new_h.capacity = cast(u32)cap;
	new_h.entries = gb_alloc_array(string16_map_allocator(), String16MapEntry<T>, new_h.capacity);

	if (h->count) {
		for (u32 i = 0; i < h->capacity; i++) {
			auto *entry = h->entries+i;
			if (entry->hash) {
				string16_map__insert(&new_h, entry->hash, entry->key, entry->value);
			}
		}
	}
	string16_map_destroy(h);
	*h = new_h;
}

template <typename T>
gb_internal T *string16_map_get(String16Map<T> *h, u32 hash, String16 const &key) {
	if (h->count == 0) {
		return nullptr;
	}
	u32 mask = (h->capacity-1);
	u32 index = hash & mask;
	u32 original_index = index;
	do {
		auto *entry = h->entries+index;
		u32 curr_hash = entry->hash;
		if (curr_hash == 0) {
			// NOTE(bill): no found, but there isn't any key removal for this hash map
			return nullptr;
		} else if (curr_hash == hash && entry->key == key) {
			return &entry->value;
		}
		index = (index+1) & mask;
	} while (original_index != index);
	return nullptr;
}


template <typename T>
gb_internal gb_inline T *string16_map_get(String16Map<T> *h, String16HashKey const &key) {
	return string16_map_get(h, key.hash, key.string);
}

template <typename T>
gb_internal gb_inline T *string16_map_get(String16Map<T> *h, String16 const &key) {
	return string16_map_get(h, string_hash(key), key);
}

template <typename T>
gb_internal T &string16_map_must_get(String16Map<T> *h, u32 hash, String16 const &key) {
	T *found = string16_map_get(h, hash, key);
	GB_ASSERT(found != nullptr);
	return *found;
}

template <typename T>
gb_internal T &string16_map_must_get(String16Map<T> *h, String16HashKey const &key) {
	return string16_map_must_get(h, key.hash, key.string);
}

template <typename T>
gb_internal gb_inline T &string16_map_must_get(String16Map<T> *h, String16 const &key) {
	return string16_map_must_get(h, string_hash(key), key);
}

template <typename T>
gb_internal void string16_map_set(String16Map<T> *h, u32 hash, String16 const &key, T const &value) {
	if (h->count == 0) {
		string16_map_grow(h);
	}
	auto *found = string16_map_get(h, hash, key);
	if (found) {
		*found = value;
		return;
	}
	string16_map__insert(h, hash, key, value);
}

template <typename T>
gb_internal gb_inline void string16_map_set(String16Map<T> *h, String16 const &key, T const &value) {
	string16_map_set(h, string_hash_string(key), value);
}

template <typename T>
gb_internal gb_inline void string16_map_set(String16Map<T> *h, String16HashKey const &key, T const &value) {
	string16_map_set(h, key.hash, key.string, value);
}


template <typename T>
gb_internal gb_inline void string16_map_clear(String16Map<T> *h) {
	h->count = 0;
	gb_zero_array(h->entries, h->capacity);
}


template <typename T>
struct StringMapIterator {
	String16Map<T> *map;
	MapIndex index;

	StringMapIterator<T> &operator++() noexcept {
		for (;;) {
			++index;
			if (map->capacity == index) {
				return *this;
			}
			String16MapEntry<T> *entry = map->entries+index;
			if (entry->hash != 0) {
				return *this;
			}
		}
	}

	bool operator==(StringMapIterator<T> const &other) const noexcept {
		return this->map == other->map && this->index == other->index;
	}

	operator String16MapEntry<T> *() const {
		return map->entries+index;
	}
};


template <typename T>
gb_internal StringMapIterator<T> end(String16Map<T> &m) noexcept {
	return StringMapIterator<T>{&m, m.capacity};
}

template <typename T>
gb_internal StringMapIterator<T> const end(String16Map<T> const &m) noexcept {
	return StringMapIterator<T>{&m, m.capacity};
}



template <typename T>
gb_internal StringMapIterator<T> begin(String16Map<T> &m) noexcept {
	if (m.count == 0) {
		return end(m);
	}

	MapIndex index = 0;
	while (index < m.capacity) {
		if (m.entries[index].hash) {
			break;
		}
		index++;
	}
	return StringMapIterator<T>{&m, index};
}
template <typename T>
gb_internal StringMapIterator<T> const begin(String16Map<T> const &m) noexcept {
	if (m.count == 0) {
		return end(m);
	}

	MapIndex index = 0;
	while (index < m.capacity) {
		if (m.entries[index].hash) {
			break;
		}
		index++;
	}
	return StringMapIterator<T>{&m, index};
}

#endif