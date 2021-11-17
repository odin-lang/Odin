#define PTR_MAP_ENABLE_MULTI_MAP 1

typedef u32 MapIndex;

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
	Slice<MapIndex>           hashes;
	Array<PtrMapEntry<K, V> > entries;
};


u32 ptr_map_hash_key(uintptr key) {
#if defined(GB_ARCH_64_BIT)
	key = (~key) + (key << 21);
	key = key ^ (key >> 24);
	key = (key + (key << 3)) + (key << 8);
	key = key ^ (key >> 14);
	key = (key + (key << 2)) + (key << 4);
	key = key ^ (key << 28);
	return cast(u32)key;
#elif defined(GB_ARCH_32_BIT)
	u32 state = ((u32)key) * 747796405u + 2891336453u;
	u32 word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
	return (word >> 22u) ^ word;
#endif
}
u32 ptr_map_hash_key(void const *key) {
	return ptr_map_hash_key((uintptr)key);
}


template <typename K, typename V> void map_init             (PtrMap<K, V> *h, gbAllocator a, isize capacity = 16);
template <typename K, typename V> void map_destroy          (PtrMap<K, V> *h);
template <typename K, typename V> V *  map_get              (PtrMap<K, V> *h, K key);
template <typename K, typename V> void map_set              (PtrMap<K, V> *h, K key, V const &value);
template <typename K, typename V> void map_remove           (PtrMap<K, V> *h, K key);
template <typename K, typename V> void map_clear            (PtrMap<K, V> *h);
template <typename K, typename V> void map_grow             (PtrMap<K, V> *h);
template <typename K, typename V> void map_rehash           (PtrMap<K, V> *h, isize new_count);
template <typename K, typename V> void map_reserve          (PtrMap<K, V> *h, isize cap);

#if PTR_MAP_ENABLE_MULTI_MAP
// Mutlivalued map procedure
template <typename K, typename V> PtrMapEntry<K, V> * multi_map_find_first(PtrMap<K, V> *h, K key);
template <typename K, typename V> PtrMapEntry<K, V> * multi_map_find_next (PtrMap<K, V> *h, PtrMapEntry<K, V> *e);

template <typename K, typename V> isize multi_map_count     (PtrMap<K, V> *h, K key);
template <typename K, typename V> void  multi_map_get_all   (PtrMap<K, V> *h, K key, V *items);
template <typename K, typename V> void  multi_map_insert    (PtrMap<K, V> *h, K key, V const &value);
template <typename K, typename V> void  multi_map_remove    (PtrMap<K, V> *h, K key, PtrMapEntry<K, V> *e);
template <typename K, typename V> void  multi_map_remove_all(PtrMap<K, V> *h, K key);
#endif

template <typename K, typename V>
gb_inline void map_init(PtrMap<K, V> *h, gbAllocator a, isize capacity) {
	capacity = next_pow2_isize(capacity);
	slice_init(&h->hashes,  a, capacity);
	array_init(&h->entries, a, 0, capacity);
	for (isize i = 0; i < capacity; i++) {
		h->hashes.data[i] = MAP_SENTINEL;
	}
}

template <typename K, typename V>
gb_inline void map_destroy(PtrMap<K, V> *h) {
	slice_free(&h->hashes, h->entries.allocator);
	array_free(&h->entries);
}

template <typename K, typename V>
gb_internal MapIndex map__add_entry(PtrMap<K, V> *h, K key) {
	PtrMapEntry<K, V> e = {};
	e.key = key;
	e.next = MAP_SENTINEL;
	array_add(&h->entries, e);
	return cast(MapIndex)(h->entries.count-1);
}

template <typename K, typename V>
gb_internal MapFindResult map__find(PtrMap<K, V> *h, K key) {
	MapFindResult fr = {MAP_SENTINEL, MAP_SENTINEL, MAP_SENTINEL};
	if (h->hashes.count == 0) {
		return fr;
	}
	u32 hash = ptr_map_hash_key(key);
	fr.hash_index = cast(MapIndex)(hash & (h->hashes.count-1));
	fr.entry_index = h->hashes.data[fr.hash_index];
	while (fr.entry_index != MAP_SENTINEL) {
		if (h->entries.data[fr.entry_index].key == key) {
			return fr;
		}
		fr.entry_prev = fr.entry_index;
		fr.entry_index = h->entries.data[fr.entry_index].next;
	}
	return fr;
}

template <typename K, typename V>
gb_internal MapFindResult map__find_from_entry(PtrMap<K, V> *h, PtrMapEntry<K, V> *e) {
	MapFindResult fr = {MAP_SENTINEL, MAP_SENTINEL, MAP_SENTINEL};
	if (h->hashes.count == 0) {
		return fr;
	}
	u32 hash = ptr_map_hash_key(e->key);
	fr.hash_index  = cast(MapIndex)(hash & (h->hashes.count-1));
	fr.entry_index = h->hashes.data[fr.hash_index];
	while (fr.entry_index != MAP_SENTINEL) {
		if (&h->entries.data[fr.entry_index] == e) {
			return fr;
		}
		fr.entry_prev = fr.entry_index;
		fr.entry_index = h->entries.data[fr.entry_index].next;
	}
	return fr;
}

template <typename K, typename V>
gb_internal b32 map__full(PtrMap<K, V> *h) {
	return 0.75f * h->hashes.count <= h->entries.count;
}

template <typename K, typename V>
gb_inline void map_grow(PtrMap<K, V> *h) {
	isize new_count = gb_max(h->hashes.count<<1, 16);
	map_rehash(h, new_count);
}

template <typename K, typename V>
void map_reset_entries(PtrMap<K, V> *h) {
	for (isize i = 0; i < h->hashes.count; i++) {
		h->hashes.data[i] = MAP_SENTINEL;
	}
	for (isize i = 0; i < h->entries.count; i++) {
		MapFindResult fr;
		PtrMapEntry<K, V> *e = &h->entries.data[i];
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
void map_reserve(PtrMap<K, V> *h, isize cap) {
	array_reserve(&h->entries, cap);
	if (h->entries.count*2 < h->hashes.count) {
		return;
	}
	slice_resize(&h->hashes, h->entries.allocator, cap*2);
	map_reset_entries(h);
}


template <typename K, typename V>
void map_rehash(PtrMap<K, V> *h, isize new_count) {
	map_reserve(h, new_count);
}

template <typename K, typename V>
V *map_get(PtrMap<K, V> *h, K key) {
	MapIndex index = map__find(h, key).entry_index;
	if (index != MAP_SENTINEL) {
		return &h->entries.data[index].value;
	}
	return nullptr;
}

template <typename K, typename V>
V &map_must_get(PtrMap<K, V> *h, K key) {
	MapIndex index = map__find(h, key).entry_index;
	GB_ASSERT(index != MAP_SENTINEL);
	return h->entries.data[index].value;
}

template <typename K, typename V>
void map_set(PtrMap<K, V> *h, K key, V const &value) {
	MapIndex index;
	MapFindResult fr;
	if (h->hashes.count == 0) {
		map_grow(h);
	}
	fr = map__find(h, key);
	if (fr.entry_index != MAP_SENTINEL) {
		index = fr.entry_index;
	} else {
		index = map__add_entry(h, key);
		if (fr.entry_prev != MAP_SENTINEL) {
			h->entries.data[fr.entry_prev].next = index;
		} else {
			h->hashes.data[fr.hash_index] = index;
		}
	}
	h->entries.data[index].value = value;

	if (map__full(h)) {
		map_grow(h);
	}
}


template <typename K, typename V>
void map__erase(PtrMap<K, V> *h, MapFindResult const &fr) {
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
	array_pop(&h->entries);
	
	last = map__find(h, h->entries.data[fr.entry_index].key);
	if (last.entry_prev != MAP_SENTINEL) {
		h->entries.data[last.entry_prev].next = fr.entry_index;
	} else {
		h->hashes.data[last.hash_index] = fr.entry_index;
	}
}

template <typename K, typename V>
void map_remove(PtrMap<K, V> *h, K key) {
	MapFindResult fr = map__find(h, key);
	if (fr.entry_index != MAP_SENTINEL) {
		map__erase(h, fr);
	}
}

template <typename K, typename V>
gb_inline void map_clear(PtrMap<K, V> *h) {
	array_clear(&h->entries);
	for (isize i = 0; i < h->hashes.count; i++) {
		h->hashes.data[i] = MAP_SENTINEL;
	}
}


#if PTR_MAP_ENABLE_MULTI_MAP
template <typename K, typename V>
PtrMapEntry<K, V> *multi_map_find_first(PtrMap<K, V> *h, K key) {
	MapIndex i = map__find(h, key).entry_index;
	if (i == MAP_SENTINEL) {
		return nullptr;
	}
	return &h->entries.data[i];
}

template <typename K, typename V>
PtrMapEntry<K, V> *multi_map_find_next(PtrMap<K, V> *h, PtrMapEntry<K, V> *e) {
	MapIndex i = e->next;
	while (i != MAP_SENTINEL) {
		if (h->entries.data[i].key == e->key) {
			return &h->entries.data[i];
		}
		i = h->entries.data[i].next;
	}
	return nullptr;
}

template <typename K, typename V>
isize multi_map_count(PtrMap<K, V> *h, K key) {
	isize count = 0;
	PtrMapEntry<K, V> *e = multi_map_find_first(h, key);
	while (e != nullptr) {
		count++;
		e = multi_map_find_next(h, e);
	}
	return count;
}

template <typename K, typename V>
void multi_map_get_all(PtrMap<K, V> *h, K key, V *items) {
	isize i = 0;
	PtrMapEntry<K, V> *e = multi_map_find_first(h, key);
	while (e != nullptr) {
		items[i++] = e->value;
		e = multi_map_find_next(h, e);
	}
}

template <typename K, typename V>
void multi_map_insert(PtrMap<K, V> *h, K key, V const &value) {
	MapFindResult fr;
	MapIndex i;
	if (h->hashes.count == 0) {
		map_grow(h);
	}
	// Make
	fr = map__find(h, key);
	i = map__add_entry(h, key);
	if (fr.entry_prev == MAP_SENTINEL) {
		h->hashes.data[fr.hash_index] = i;
	} else {
		h->entries.data[fr.entry_prev].next = i;
	}
	h->entries.data[i].next = fr.entry_index;
	h->entries.data[i].value = value;
	// Grow if needed
	if (map__full(h)) {
		map_grow(h);
	}
}

template <typename K, typename V>
void multi_map_remove(PtrMap<K, V> *h, K key, PtrMapEntry<K, V> *e) {
	MapFindResult fr = map__find_from_entry(h, e);
	if (fr.entry_index != MAP_SENTINEL) {
		map__erase(h, fr);
	}
}

template <typename K, typename V>
void multi_map_remove_all(PtrMap<K, V> *h, K key) {
	while (map_get(h, key) != nullptr) {
		map_remove(h, key);
	}
}
#endif
