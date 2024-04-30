#define PTR_MAP_ENABLE_MULTI_MAP 1

typedef u32 MapIndex;

enum {
	MAP_CACHE_LINE_SIZE_POW = 6,
	MAP_CACHE_LINE_SIZE = 1<<MAP_CACHE_LINE_SIZE_POW,
	MAP_CACHE_LINE_MASK = MAP_CACHE_LINE_SIZE-1,
};


struct MapFindResult {
	MapIndex hash_index;
	MapIndex entry_prev;
	MapIndex entry_index;
};

enum : MapIndex { MAP_SENTINEL = ~(MapIndex)0 };
static void *const MAP_TOMBSTONE = (void *)~(uintptr)0;

template <typename K, typename V>
struct PtrMapEntry {
	static_assert(sizeof(K) == sizeof(void *), "Key size must be pointer size");
	
	K key;
	V value;
};

template <typename K, typename V>
struct PtrMap {
	PtrMapEntry<K, V> *entries;
	u32                count;
	u32                capacity;
};


gb_internal gb_inline u32 ptr_map_hash_key(uintptr key) {
	u32 res;
#if defined(GB_ARCH_64_BIT)
	key = (~key) + (key << 21);
	key = key ^ (key >> 24);
	key = (key + (key << 3)) + (key << 8);
	key = key ^ (key >> 14);
	key = (key + (key << 2)) + (key << 4);
	key = key ^ (key << 28);
	res = cast(u32)key;
#elif defined(GB_ARCH_32_BIT)
	u32 state = (cast(u32)key) * 747796405u + 2891336453u;
	u32 word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
	res = (word >> 22u) ^ word;
#endif
	return res;
}
gb_internal gb_inline u32 ptr_map_hash_key(void const *key) {
	return ptr_map_hash_key((uintptr)key);
}


template <typename K, typename V> gb_internal void map_init             (PtrMap<K, V> *h, isize capacity = 16);
template <typename K, typename V> gb_internal void map_destroy          (PtrMap<K, V> *h);
template <typename K, typename V> gb_internal V *  map_get              (PtrMap<K, V> *h, K key);
template <typename K, typename V> gb_internal void map_set              (PtrMap<K, V> *h, K key, V const &value);
template <typename K, typename V> gb_internal bool map_set_if_not_previously_exists(PtrMap<K, V> *h, K key, V const &value); // returns true if it previously existed
template <typename K, typename V> gb_internal void map_remove           (PtrMap<K, V> *h, K key);
template <typename K, typename V> gb_internal void map_clear            (PtrMap<K, V> *h);
template <typename K, typename V> gb_internal void map_grow             (PtrMap<K, V> *h);
template <typename K, typename V> gb_internal void map_rehash           (PtrMap<K, V> *h, isize new_count);
template <typename K, typename V> gb_internal void map_reserve          (PtrMap<K, V> *h, isize cap);

// Mutlivalued map procedure
template <typename K, typename V> gb_internal PtrMapEntry<K, V> * multi_map_find_first(PtrMap<K, V> *h, K key);
template <typename K, typename V> gb_internal PtrMapEntry<K, V> * multi_map_find_next (PtrMap<K, V> *h, PtrMapEntry<K, V> *e);

template <typename K, typename V> gb_internal isize multi_map_count     (PtrMap<K, V> *h, K key);
template <typename K, typename V> gb_internal void  multi_map_get_all   (PtrMap<K, V> *h, K key, V *items);
template <typename K, typename V> gb_internal void  multi_map_insert    (PtrMap<K, V> *h, K key, V const &value);
template <typename K, typename V> gb_internal void  multi_map_remove    (PtrMap<K, V> *h, K key, PtrMapEntry<K, V> *e);
template <typename K, typename V> gb_internal void  multi_map_remove_all(PtrMap<K, V> *h, K key);

gb_internal gbAllocator map_allocator(void) {
	return heap_allocator();
}

template <typename K, typename V>
gb_internal gb_inline void map_init(PtrMap<K, V> *h, isize capacity) {
	capacity = next_pow2_isize(capacity);
	map_reserve(h, capacity);
}

template <typename K, typename V>
gb_internal gb_inline void map_destroy(PtrMap<K, V> *h) {
	gbAllocator a = map_allocator();
	gb_free(a, h->entries);
}


template <typename K, typename V>
gb_internal void map__insert(PtrMap<K, V> *h, K key, V const &value) {
	if (h->count+1 >= h->capacity) {
		map_grow(h);
	}
	u32 hash = ptr_map_hash_key(key);
	u32 mask = h->capacity-1;
	MapIndex index = hash & mask;
	MapIndex original_index = index;
	do {
		auto *entry = h->entries+index;
		if (!entry->key || entry->key == cast(K)MAP_TOMBSTONE) {
			entry->key   = key;
			entry->value = value;
			h->count += 1;
			return;
		}
		index = (index+1)&mask;
	} while (index != original_index);

	GB_PANIC("FAILED TO INSERT");
}

template <typename K, typename V>
gb_internal b32 map__full(PtrMap<K, V> *h) {
	return 0.75f * h->capacity <= h->count;
}

template <typename K, typename V>
gb_internal gb_inline void map_grow(PtrMap<K, V> *h) {
	isize new_capacity = gb_max(h->capacity<<1, 16);
	map_reserve(h, new_capacity);
}

template <typename K, typename V>
gb_internal void try_map_grow(PtrMap<K, V> *h) {
	if (h->capacity == 0 || map__full(h)) {
		map_grow(h);
	}
}


template <typename K, typename V>
gb_internal void map_reserve(PtrMap<K, V> *h, isize cap) {
	if (cap < h->capacity) {
		return;
	}
	cap = next_pow2_isize(cap);
	typedef PtrMapEntry<K, V> EntryType;

	PtrMap<K, V> new_h = {};
	new_h.count    = 0;
	new_h.capacity = cast(u32)cap;
	new_h.entries = gb_alloc_array(map_allocator(), EntryType, new_h.capacity);

	if (h->count) {
		for (u32 i = 0; i < h->capacity; i++) {
			auto *entry = h->entries+i;
			if (entry->key &&
			    entry->key != cast(K)MAP_TOMBSTONE) {
				map__insert(&new_h, entry->key, entry->value);
			}
		}
	}
	map_destroy(h);
	*h = new_h;
}

template <typename K, typename V>
gb_internal V *map_get(PtrMap<K, V> *h, K key) {
	if (h->count == 0) {
		return nullptr;
	}
	if (key == 0) {
		GB_PANIC("0 key");
	}

	u32 hash = ptr_map_hash_key(key);
	u32 mask = (h->capacity-1);
	u32 index = hash & mask;
	u32 original_index = index;
	do {
		auto *entry = h->entries+index;
		if (!entry->key) {
			// NOTE(bill): no found, but there isn't any key removal for this hash map
			return nullptr;
		} else if (entry->key == key) {
			return &entry->value;
		}
		index = (index+1) & mask;
	} while (original_index != index);
	return nullptr;
}
template <typename K, typename V>
gb_internal V *map_try_get(PtrMap<K, V> *h, K key, MapIndex *found_index_) {
	if (found_index_) *found_index_ = ~(MapIndex)0;

	if (h->count == 0) {
		return nullptr;
	}
	if (key == 0) {
		GB_PANIC("0 key");
	}

	u32 hash = ptr_map_hash_key(key);
	u32 mask = (h->capacity-1);
	u32 index = hash & mask;
	u32 original_index = index;
	do {
		auto *entry = h->entries+index;
		if (!entry->key) {
			// NOTE(bill): no found, but there isn't any key removal for this hash map
			return nullptr;
		} else if (entry->key == key) {
			if (found_index_) *found_index_ = index;
			return &entry->value;
		}
		index = (index+1) & mask;
	} while (original_index != index);
	return nullptr;
}


template <typename K, typename V>
gb_internal void map_set_internal_from_try_get(PtrMap<K, V> *h, K key, V const &value, MapIndex found_index) {
	if (found_index != MAP_SENTINEL) {
		GB_ASSERT(h->entries[found_index].key == key);
		h->entries[found_index].value = value;
	} else {
		map_set(h, key, value);
	}
}

template <typename K, typename V>
gb_internal V &map_must_get(PtrMap<K, V> *h, K key) {
	V *ptr = map_get(h, key);
	GB_ASSERT(ptr != nullptr);
	return *ptr;
}

template <typename K, typename V>
gb_internal void map_set(PtrMap<K, V> *h, K key, V const &value) {
	GB_ASSERT(key != 0);
	try_map_grow(h);
	auto *found = map_get(h, key);
	if (found) {
		*found = value;
		return;
	}
	map__insert(h, key, value);
}

// returns true if it previously existed
template <typename K, typename V>
gb_internal bool map_set_if_not_previously_exists(PtrMap<K, V> *h, K key, V const &value) {
	try_map_grow(h);
	auto *found = map_get(h, key);
	if (found) {
		return true;
	}
	map__insert(h, key, value);
	return false;
}


template <typename K, typename V>
gb_internal void map_remove(PtrMap<K, V> *h, K key) {
	MapIndex found_index = 0;
	if (map_try_get(h, key, &found_index)) {
		h->entries[found_index].key = cast(K)MAP_TOMBSTONE;
		h->count -= 1;
	}
}

template <typename K, typename V>
gb_internal gb_inline void map_clear(PtrMap<K, V> *h) {
	h->count = 0;
	gb_zero_array(h->entries, h->capacity);
}


#if PTR_MAP_ENABLE_MULTI_MAP
template <typename K, typename V>
gb_internal PtrMapEntry<K, V> *multi_map_find_first(PtrMap<K, V> *h, K key) {
	if (h->count == 0) {
		return nullptr;
	}
	u32 hash = ptr_map_hash_key(key);
	u32 mask = (h->capacity-1);
	u32 index = hash & mask;
	u32 original_index = index;
	do {
		auto *entry = h->entries+index;
		if (!entry->key) {
			// NOTE(bill): no found, but there isn't any key removal for this hash map
			return nullptr;
		} else if (entry->key == key) {
			return entry;
		}
		index = (index+1) & mask;
	} while (original_index != index);
	return nullptr;
}

template <typename K, typename V>
gb_internal PtrMapEntry<K, V> *multi_map_find_next(PtrMap<K, V> *h, PtrMapEntry<K, V> *e) {
	u32 mask = h->capacity-1;
	MapIndex index = cast(MapIndex)(e - h->entries);
	MapIndex original_index = index;
	do {
		index = (index+1)&mask;
		auto *entry = h->entries+index;
		if (!entry->key) {
			return nullptr;
		}
		if (entry->key == e->key) {
			return entry;
		}
	} while (original_index != index);
	return nullptr;
}

template <typename K, typename V>
gb_internal isize multi_map_count(PtrMap<K, V> *h, K key) {
	isize count = 0;
	PtrMapEntry<K, V> *e = multi_map_find_first(h, key);
	while (e != nullptr) {
		count++;
		e = multi_map_find_next(h, e);
	}
	return count;
}

template <typename K, typename V>
gb_internal void multi_map_get_all(PtrMap<K, V> *h, K key, V *items) {
	usize i = 0;
	PtrMapEntry<K, V> *e = multi_map_find_first(h, key);
	while (e != nullptr) {
		items[i++] = e->value;
		e = multi_map_find_next(h, e);
	}
}

template <typename K, typename V>
gb_internal void multi_map_insert(PtrMap<K, V> *h, K key, V const &value) {
	try_map_grow(h);
	map__insert(h, key, value);
}

// template <typename K, typename V>
// gb_internal void multi_map_remove(PtrMap<K, V> *h, K key, PtrMapEntry<K, V> *e) {
// 	if (fr.entry_index != MAP_SENTINEL) {
// 		map__erase(h, fr);
// 	}
// }

template <typename K, typename V>
gb_internal void multi_map_remove_all(PtrMap<K, V> *h, K key) {
	while (map_get(h, key) != nullptr) {
		map_remove(h, key);
	}
}
#endif




template <typename K, typename V>
struct PtrMapIterator {
	PtrMap<K, V> *map;
	MapIndex index;

	PtrMapIterator<K, V> &operator++() noexcept {
		for (;;) {
			++index;
			if (map->capacity == index) {
				return *this;
			}
			PtrMapEntry<K, V> *entry = map->entries+index;
			if (entry->key && entry->key != cast(K)MAP_TOMBSTONE) {
				return *this;
			}
		}
	}

	bool operator==(PtrMapIterator<K, V> const &other) const noexcept {
		return this->map == other->map && this->index == other->index;
	}

	operator PtrMapEntry<K, V> *() const {
		return map->entries+index;
	}
};


template <typename K, typename V>
gb_internal PtrMapIterator<K, V> end(PtrMap<K, V> &m) noexcept {
	return PtrMapIterator<K, V>{&m, m.capacity};
}

template <typename K, typename V>
gb_internal PtrMapIterator<K, V> const end(PtrMap<K, V> const &m) noexcept {
	return PtrMapIterator<K, V>{&m, m.capacity};
}



template <typename K, typename V>
gb_internal PtrMapIterator<K, V> begin(PtrMap<K, V> &m) noexcept {
	if (m.count == 0) {
		return end(m);
	}

	MapIndex index = 0;
	while (index < m.capacity) {
		auto key = m.entries[index].key;
		if (key && key != cast(K)MAP_TOMBSTONE) {
			break;
		}
		index++;
	}
	return PtrMapIterator<K, V>{&m, index};
}
template <typename K, typename V>
gb_internal PtrMapIterator<K, V> const begin(PtrMap<K, V> const &m) noexcept {
	if (m.count == 0) {
		return end(m);
	}

	MapIndex index = 0;
	while (index < m.capacity) {
		auto key = m.entries[index].key;
		if (key && key != cast(K)MAP_TOMBSTONE) {
			break;
		}
		index++;
	}
	return PtrMapIterator<K, V>{&m, index};
}
