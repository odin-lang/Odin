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

template <typename K, typename V>
struct PtrMapEntry {
	static_assert(sizeof(K) == sizeof(void *), "Key size must be pointer size");
	
	K        key;
	V        value;
	MapIndex next;
};

template <typename K, typename V>
struct PtrMap {
	MapIndex *         hashes;
	usize              hashes_count;
	PtrMapEntry<K, V> *entries;
	u32                count;
	u32                entries_capacity;
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

#if PTR_MAP_ENABLE_MULTI_MAP
// Mutlivalued map procedure
template <typename K, typename V> gb_internal PtrMapEntry<K, V> * multi_map_find_first(PtrMap<K, V> *h, K key);
template <typename K, typename V> gb_internal PtrMapEntry<K, V> * multi_map_find_next (PtrMap<K, V> *h, PtrMapEntry<K, V> *e);

template <typename K, typename V> gb_internal isize multi_map_count     (PtrMap<K, V> *h, K key);
template <typename K, typename V> gb_internal void  multi_map_get_all   (PtrMap<K, V> *h, K key, V *items);
template <typename K, typename V> gb_internal void  multi_map_insert    (PtrMap<K, V> *h, K key, V const &value);
template <typename K, typename V> gb_internal void  multi_map_remove    (PtrMap<K, V> *h, K key, PtrMapEntry<K, V> *e);
template <typename K, typename V> gb_internal void  multi_map_remove_all(PtrMap<K, V> *h, K key);
#endif

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
	gb_free(a, h->hashes);
	gb_free(a, h->entries);
}

template <typename K, typename V>
gb_internal void map__resize_hashes(PtrMap<K, V> *h, usize count) {
	h->hashes_count = cast(u32)resize_array_raw(&h->hashes, map_allocator(), h->hashes_count, count, MAP_CACHE_LINE_SIZE);
}

template <typename K, typename V>
gb_internal void map__reserve_entries(PtrMap<K, V> *h, usize capacity) {
	h->entries_capacity = cast(u32)resize_array_raw(&h->entries, map_allocator(), h->entries_capacity, capacity, MAP_CACHE_LINE_SIZE);
}


template <typename K, typename V>
gb_internal MapIndex map__add_entry(PtrMap<K, V> *h, K key) {
	PtrMapEntry<K, V> e = {};
	e.key = key;
	e.next = MAP_SENTINEL;
	if (h->count+1 >= h->entries_capacity) {
		map__reserve_entries(h, gb_max(h->entries_capacity*2, 4));
	}
	h->entries[h->count++] = e;
	return cast(MapIndex)(h->count-1);
}

template <typename K, typename V>
gb_internal MapFindResult map__find(PtrMap<K, V> *h, K key) {
	MapFindResult fr = {MAP_SENTINEL, MAP_SENTINEL, MAP_SENTINEL};
	if (h->hashes_count == 0) {
		return fr;
	}
	u32 hash = ptr_map_hash_key(key);
	fr.hash_index = cast(MapIndex)(hash & (h->hashes_count-1));
	fr.entry_index = h->hashes[fr.hash_index];
	while (fr.entry_index != MAP_SENTINEL) {
		auto *entry = &h->entries[fr.entry_index];
		if (entry->key == key) {
			return fr;
		}
		fr.entry_prev = fr.entry_index;
		fr.entry_index = entry->next;
	}
	return fr;
}

template <typename K, typename V>
gb_internal MapFindResult map__find_from_entry(PtrMap<K, V> *h, PtrMapEntry<K, V> *e) {
	MapFindResult fr = {MAP_SENTINEL, MAP_SENTINEL, MAP_SENTINEL};
	if (h->hashes_count == 0) {
		return fr;
	}
	u32 hash = ptr_map_hash_key(e->key);
	fr.hash_index  = cast(MapIndex)(hash & (h->hashes_count-1));
	fr.entry_index = h->hashes[fr.hash_index];
	while (fr.entry_index != MAP_SENTINEL) {
		if (&h->entries[fr.entry_index] == e) {
			return fr;
		}
		fr.entry_prev = fr.entry_index;
		fr.entry_index = h->entries[fr.entry_index].next;
	}
	return fr;
}

template <typename K, typename V>
gb_internal b32 map__full(PtrMap<K, V> *h) {
	return 0.75f * h->hashes_count <= h->count;
}

template <typename K, typename V>
gb_internal gb_inline void map_grow(PtrMap<K, V> *h) {
	isize new_count = gb_max(h->hashes_count<<1, 16);
	map_rehash(h, new_count);
}

template <typename K, typename V>
gb_internal void map_reset_entries(PtrMap<K, V> *h) {
	for (usize i = 0; i < h->hashes_count; i++) {
		h->hashes[i] = MAP_SENTINEL;
	}
	for (usize i = 0; i < h->count; i++) {
		MapFindResult fr;
		PtrMapEntry<K, V> *e = &h->entries[i];
		e->next = MAP_SENTINEL;
		fr = map__find_from_entry(h, e);
		if (fr.entry_prev == MAP_SENTINEL) {
			h->hashes[fr.hash_index] = cast(MapIndex)i;
		} else {
			h->entries[fr.entry_prev].next = cast(MapIndex)i;
		}
	}
}

template <typename K, typename V>
gb_internal void map_reserve(PtrMap<K, V> *h, isize cap) {
	if (h->count*2 < h->hashes_count) {
		return;
	}
	map__reserve_entries(h, cap);
	map__resize_hashes(h, cap*2);
	map_reset_entries(h);
}


template <typename K, typename V>
gb_internal void map_rehash(PtrMap<K, V> *h, isize new_count) {
	map_reserve(h, new_count);
}

template <typename K, typename V>
gb_internal V *map_get(PtrMap<K, V> *h, K key) {
	MapIndex hash_index  = MAP_SENTINEL;
	MapIndex entry_prev  = MAP_SENTINEL;
	MapIndex entry_index = MAP_SENTINEL;
	if (h->hashes_count != 0) {
		u32 hash = ptr_map_hash_key(key);
		hash_index = cast(MapIndex)(hash & (h->hashes_count-1));
		entry_index = h->hashes[hash_index];
		while (entry_index != MAP_SENTINEL) {
			auto *entry = &h->entries[entry_index];
			if (entry->key == key) {
				return &entry->value;
			}
			entry_prev = entry_index;
			entry_index = entry->next;
		}
	}
	return nullptr;
}
template <typename K, typename V>
gb_internal V *map_try_get(PtrMap<K, V> *h, K key, MapFindResult *fr_) {
	MapFindResult fr = {MAP_SENTINEL, MAP_SENTINEL, MAP_SENTINEL};
	if (h->hashes_count != 0) {
		u32 hash = ptr_map_hash_key(key);
		fr.hash_index = cast(MapIndex)(hash & (h->hashes_count-1));
		fr.entry_index = h->hashes[fr.hash_index];
		while (fr.entry_index != MAP_SENTINEL) {
			auto *entry = &h->entries[fr.entry_index];
			if (entry->key == key) {
				return &entry->value;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = entry->next;
		}
	}
	if (h->hashes_count == 0 || map__full(h)) {
		map_grow(h);
	}
	if (fr_) *fr_ = fr;
	return nullptr;
}


template <typename K, typename V>
gb_internal void map_set_internal_from_try_get(PtrMap<K, V> *h, K key, V const &value, MapFindResult const &fr) {
	MapIndex index = map__add_entry(h, key);
	if (fr.entry_prev != MAP_SENTINEL) {
		h->entries[fr.entry_prev].next = index;
	} else {
		h->hashes[fr.hash_index] = index;
	}
	h->entries[index].value = value;
}

template <typename K, typename V>
gb_internal V &map_must_get(PtrMap<K, V> *h, K key) {
	V *ptr = map_get(h, key);
	GB_ASSERT(ptr != nullptr);
	return *ptr;
}

template <typename K, typename V>
gb_internal void map_set(PtrMap<K, V> *h, K key, V const &value) {
	MapIndex index;
	MapFindResult fr;
	if (h->hashes_count == 0) {
		map_grow(h);
	}
	fr = map__find(h, key);
	if (fr.entry_index != MAP_SENTINEL) {
		index = fr.entry_index;
	} else {
		index = map__add_entry(h, key);
		if (fr.entry_prev != MAP_SENTINEL) {
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

// returns true if it previously existed
template <typename K, typename V>
gb_internal bool map_set_if_not_previously_exists(PtrMap<K, V> *h, K key, V const &value) {
	MapIndex index;
	MapFindResult fr;
	if (h->hashes_count == 0) {
		map_grow(h);
	}
	fr = map__find(h, key);
	if (fr.entry_index != MAP_SENTINEL) {
		return true;
	} else {
		index = map__add_entry(h, key);
		if (fr.entry_prev != MAP_SENTINEL) {
			h->entries[fr.entry_prev].next = index;
		} else {
			h->hashes[fr.hash_index] = index;
		}
	}
	h->entries[index].value = value;

	if (map__full(h)) {
		map_grow(h);
	}
	return false;
}


template <typename K, typename V>
gb_internal void map__erase(PtrMap<K, V> *h, MapFindResult const &fr) {
	MapFindResult last;
	if (fr.entry_prev == MAP_SENTINEL) {
		h->hashes[fr.hash_index] = h->entries[fr.entry_index].next;
	} else {
		h->entries[fr.entry_prev].next = h->entries[fr.entry_index].next;
	}
	if (fr.entry_index == h->count-1) {
		h->count--;
		return;
	}
	h->entries[fr.entry_index] = h->entries[h->count-1];
	h->count--;
	
	last = map__find(h, h->entries[fr.entry_index].key);
	if (last.entry_prev != MAP_SENTINEL) {
		h->entries[last.entry_prev].next = fr.entry_index;
	} else {
		h->hashes[last.hash_index] = fr.entry_index;
	}
}

template <typename K, typename V>
gb_internal void map_remove(PtrMap<K, V> *h, K key) {
	MapFindResult fr = map__find(h, key);
	if (fr.entry_index != MAP_SENTINEL) {
		map__erase(h, fr);
	}
}

template <typename K, typename V>
gb_internal gb_inline void map_clear(PtrMap<K, V> *h) {
	h->count = 0;
	for (usize i = 0; i < h->hashes_count; i++) {
		h->hashes[i] = MAP_SENTINEL;
	}
}


#if PTR_MAP_ENABLE_MULTI_MAP
template <typename K, typename V>
gb_internal PtrMapEntry<K, V> *multi_map_find_first(PtrMap<K, V> *h, K key) {
	MapIndex i = map__find(h, key).entry_index;
	if (i == MAP_SENTINEL) {
		return nullptr;
	}
	return &h->entries[i];
}

template <typename K, typename V>
gb_internal PtrMapEntry<K, V> *multi_map_find_next(PtrMap<K, V> *h, PtrMapEntry<K, V> *e) {
	MapIndex i = e->next;
	while (i != MAP_SENTINEL) {
		if (h->entries[i].key == e->key) {
			return &h->entries[i];
		}
		i = h->entries[i].next;
	}
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
	MapFindResult fr;
	MapIndex i;
	if (h->hashes_count == 0) {
		map_grow(h);
	}
	// Make
	fr = map__find(h, key);
	i = map__add_entry(h, key);
	if (fr.entry_prev == MAP_SENTINEL) {
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

template <typename K, typename V>
gb_internal void multi_map_remove(PtrMap<K, V> *h, K key, PtrMapEntry<K, V> *e) {
	MapFindResult fr = map__find_from_entry(h, e);
	if (fr.entry_index != MAP_SENTINEL) {
		map__erase(h, fr);
	}
}

template <typename K, typename V>
gb_internal void multi_map_remove_all(PtrMap<K, V> *h, K key) {
	while (map_get(h, key) != nullptr) {
		map_remove(h, key);
	}
}
#endif


template <typename K, typename V>
gb_internal PtrMapEntry<K, V> *begin(PtrMap<K, V> &m) {
	return m.entries;
}
template <typename K, typename V>
gb_internal PtrMapEntry<K, V> const *begin(PtrMap<K, V> const &m) {
	return m.entries;
}


template <typename K, typename V>
gb_internal PtrMapEntry<K, V> *end(PtrMap<K, V> &m) {
	return m.entries + m.count;
}

template <typename K, typename V>
gb_internal PtrMapEntry<K, V> const *end(PtrMap<K, V> const &m) {
	return m.entries + m.count;
}
