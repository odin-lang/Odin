GB_STATIC_ASSERT(sizeof(MapIndex) == sizeof(u32));


struct StringHashKey {
	String string;
	u32    hash;

	operator String() const noexcept {
		return this->string;
	}
	operator String const &() const noexcept {
		return this->string;
	}
};
gb_internal gb_inline u32 string_hash(String const &s) {
	u32 res = fnv32a(s.text, s.len) & 0x7fffffff;
	return res | (res == 0);
}

gb_internal gb_inline StringHashKey string_hash_string(String const &s) {
	StringHashKey hash_key = {};
	hash_key.hash = string_hash(s);
	hash_key.string = s;
	return hash_key;
}

template <typename T>
struct StringMapEntry {
	String key;
	u32    hash;
	T      value;
};

template <typename T>
struct StringMap {
	StringMapEntry<T> *entries;
	u32                count;
	u32                capacity;
};


template <typename T> gb_internal void string_map_init    (StringMap<T> *h, usize capacity = 16);
template <typename T> gb_internal void string_map_destroy (StringMap<T> *h);

template <typename T> gb_internal T *  string_map_get     (StringMap<T> *h, char const *key);
template <typename T> gb_internal T *  string_map_get     (StringMap<T> *h, String const &key);
template <typename T> gb_internal T *  string_map_get     (StringMap<T> *h, StringHashKey const &key);

template <typename T> gb_internal T &  string_map_must_get(StringMap<T> *h, char const *key);
template <typename T> gb_internal T &  string_map_must_get(StringMap<T> *h, String const &key);
template <typename T> gb_internal T &  string_map_must_get(StringMap<T> *h, StringHashKey const &key);

template <typename T> gb_internal void string_map_set     (StringMap<T> *h, char const *key,   T const &value);
template <typename T> gb_internal void string_map_set     (StringMap<T> *h, String const &key, T const &value);
template <typename T> gb_internal void string_map_set     (StringMap<T> *h, StringHashKey const &key, T const &value);

// template <typename T> gb_internal void string_map_remove  (StringMap<T> *h, StringHashKey const &key);
template <typename T> gb_internal void string_map_clear   (StringMap<T> *h);
template <typename T> gb_internal void string_map_grow    (StringMap<T> *h);
template <typename T> gb_internal void string_map_reserve (StringMap<T> *h, usize new_count);

gb_internal gbAllocator string_map_allocator(void) {
	return heap_allocator();
}

template <typename T>
gb_internal gb_inline void string_map_init(StringMap<T> *h, usize capacity) {
	capacity = next_pow2_isize(capacity);
	string_map_reserve(h, capacity);
}

template <typename T>
gb_internal gb_inline void string_map_destroy(StringMap<T> *h) {
	gb_free(string_map_allocator(), h->entries);
}


template <typename T>
gb_internal void string_map__insert(StringMap<T> *h, u32 hash, String const &key, T const &value) {
	if (h->count+1 >= h->capacity) {
		string_map_grow(h);
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
gb_internal b32 string_map__full(StringMap<T> *h) {
	return 0.75f * h->count <= h->capacity;
}

template <typename T>
gb_inline void string_map_grow(StringMap<T> *h) {
	isize new_capacity = gb_max(h->capacity<<1, 16);
	string_map_reserve(h, new_capacity);
}


template <typename T>
gb_internal void string_map_reserve(StringMap<T> *h, usize cap) {
	if (cap < h->capacity) {
		return;
	}
	cap = next_pow2_isize(cap);

	StringMap<T> new_h = {};
	new_h.count    = 0;
	new_h.capacity = cast(u32)cap;
	new_h.entries = gb_alloc_array(string_map_allocator(), StringMapEntry<T>, new_h.capacity);

	if (h->count) {
		for (u32 i = 0; i < h->capacity; i++) {
			auto *entry = h->entries+i;
			if (entry->hash) {
				string_map__insert(&new_h, entry->hash, entry->key, entry->value);
			}
		}
	}
	string_map_destroy(h);
	*h = new_h;
}

template <typename T>
gb_internal T *string_map_get(StringMap<T> *h, u32 hash, String const &key) {
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
gb_internal gb_inline T *string_map_get(StringMap<T> *h, StringHashKey const &key) {
	return string_map_get(h, key.hash, key.string);
}

template <typename T>
gb_internal gb_inline T *string_map_get(StringMap<T> *h, String const &key) {
	return string_map_get(h, string_hash(key), key);
}

template <typename T>
gb_internal gb_inline T *string_map_get(StringMap<T> *h, char const *key) {
	String k = make_string_c(key);
	return string_map_get(h, string_hash(k), k);
}

template <typename T>
gb_internal T &string_map_must_get(StringMap<T> *h, u32 hash, String const &key) {
	T *found = string_map_get(h, hash, key);
	GB_ASSERT(found != nullptr);
	return *found;
}

template <typename T>
gb_internal T &string_map_must_get(StringMap<T> *h, StringHashKey const &key) {
	return string_map_must_get(h, key.hash, key.string);
}

template <typename T>
gb_internal gb_inline T &string_map_must_get(StringMap<T> *h, String const &key) {
	return string_map_must_get(h, string_hash(key), key);
}

template <typename T>
gb_internal gb_inline T &string_map_must_get(StringMap<T> *h, char const *key) {
	String k = make_string_c(key);
	return string_map_must_get(h, string_hash(k), k);
}

template <typename T>
gb_internal void string_map_set(StringMap<T> *h, u32 hash, String const &key, T const &value) {
	if (h->count == 0) {
		string_map_grow(h);
	}
	auto *found = string_map_get(h, hash, key);
	if (found) {
		*found = value;
		return;
	}
	string_map__insert(h, hash, key, value);
}

template <typename T>
gb_internal gb_inline void string_map_set(StringMap<T> *h, String const &key, T const &value) {
	string_map_set(h, string_hash_string(key), value);
}

template <typename T>
gb_internal gb_inline void string_map_set(StringMap<T> *h, char const *key, T const &value) {
	string_map_set(h, string_hash_string(make_string_c(key)), value);
}

template <typename T>
gb_internal gb_inline void string_map_set(StringMap<T> *h, StringHashKey const &key, T const &value) {
	string_map_set(h, key.hash, key.string, value);
}


template <typename T>
gb_internal gb_inline void string_map_clear(StringMap<T> *h) {
	h->count = 0;
	gb_zero_array(h->entries, h->capacity);
}


template <typename T>
struct StringMapIterator {
	StringMap<T> *map;
	MapIndex index;

	StringMapIterator<T> &operator++() noexcept {
		for (;;) {
			++index;
			if (map->capacity == index) {
				return *this;
			}
			StringMapEntry<T> *entry = map->entries+index;
			if (entry->hash != 0) {
				return *this;
			}
		}
	}

	bool operator==(StringMapIterator<T> const &other) const noexcept {
		return this->map == other->map && this->index == other->index;
	}

	operator StringMapEntry<T> *() const {
		return map->entries+index;
	}
};


template <typename T>
gb_internal StringMapIterator<T> end(StringMap<T> &m) noexcept {
	return StringMapIterator<T>{&m, m.capacity};
}

template <typename T>
gb_internal StringMapIterator<T> const end(StringMap<T> const &m) noexcept {
	return StringMapIterator<T>{&m, m.capacity};
}



template <typename T>
gb_internal StringMapIterator<T> begin(StringMap<T> &m) noexcept {
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
gb_internal StringMapIterator<T> const begin(StringMap<T> const &m) noexcept {
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
