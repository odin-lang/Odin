template <typename T>
struct PtrSetEntry {
	T        ptr;
	MapIndex next;
};

template <typename T>
struct PtrSet {
	Slice<MapIndex>    hashes;
	Array<PtrSetEntry<T>> entries;
};

template <typename T> void ptr_set_init   (PtrSet<T> *s, gbAllocator a, isize capacity = 16);
template <typename T> void ptr_set_destroy(PtrSet<T> *s);
template <typename T> T    ptr_set_add    (PtrSet<T> *s, T ptr);
template <typename T> bool ptr_set_update (PtrSet<T> *s, T ptr); // returns true if it previously existsed
template <typename T> bool ptr_set_exists (PtrSet<T> *s, T ptr);
template <typename T> void ptr_set_remove (PtrSet<T> *s, T ptr);
template <typename T> void ptr_set_clear  (PtrSet<T> *s);
template <typename T> void ptr_set_grow   (PtrSet<T> *s);
template <typename T> void ptr_set_rehash (PtrSet<T> *s, isize new_count);
template <typename T> void ptr_set_reserve(PtrSet<T> *h, isize cap);


template <typename T>
void ptr_set_init(PtrSet<T> *s, gbAllocator a, isize capacity) {
	if (capacity != 0) {
		capacity = next_pow2_isize(gb_max(16, capacity));
	}

	slice_init(&s->hashes,  a, capacity);
	array_init(&s->entries, a, 0, capacity);
	for (isize i = 0; i < capacity; i++) {
		s->hashes.data[i] = MAP_SENTINEL;
	}
}

template <typename T>
void ptr_set_destroy(PtrSet<T> *s) {
	slice_free(&s->hashes, s->entries.allocator);
	array_free(&s->entries);
}

template <typename T>
gb_internal MapIndex ptr_set__add_entry(PtrSet<T> *s, T ptr) {
	PtrSetEntry<T> e = {};
	e.ptr = ptr;
	e.next = MAP_SENTINEL;
	array_add(&s->entries, e);
	return cast(MapIndex)(s->entries.count-1);
}


template <typename T>
gb_internal MapFindResult ptr_set__find(PtrSet<T> *s, T ptr) {
	MapFindResult fr = {MAP_SENTINEL, MAP_SENTINEL, MAP_SENTINEL};
	if (s->hashes.count != 0) {
		u32 hash = ptr_map_hash_key(ptr);
		fr.hash_index = cast(MapIndex)(hash & (s->hashes.count-1));
		fr.entry_index = s->hashes.data[fr.hash_index];
		while (fr.entry_index != MAP_SENTINEL) {
			if (s->entries.data[fr.entry_index].ptr == ptr) {
				return fr;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = s->entries.data[fr.entry_index].next;
		}
	}
	return fr;
}

template <typename T>
gb_internal MapFindResult ptr_set__find_from_entry(PtrSet<T> *s, PtrSetEntry<T> *e) {
	MapFindResult fr = {MAP_SENTINEL, MAP_SENTINEL, MAP_SENTINEL};
	if (s->hashes.count != 0) {
		u32 hash = ptr_map_hash_key(e->ptr);
		fr.hash_index = cast(MapIndex)(hash & (s->hashes.count-1));
		fr.entry_index = s->hashes.data[fr.hash_index];
		while (fr.entry_index != MAP_SENTINEL) {
			if (&s->entries.data[fr.entry_index] == e) {
				return fr;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = s->entries.data[fr.entry_index].next;
		}
	}
	return fr;
}

template <typename T>
gb_internal bool ptr_set__full(PtrSet<T> *s) {
	return 0.75f * s->hashes.count <= s->entries.count;
}

template <typename T>
gb_inline void ptr_set_grow(PtrSet<T> *s) {
	isize new_count = gb_max(s->hashes.count<<1, 16);
	ptr_set_rehash(s, new_count);
}

template <typename T>
void ptr_set_reset_entries(PtrSet<T> *s) {
	for (isize i = 0; i < s->hashes.count; i++) {
		s->hashes.data[i] = MAP_SENTINEL;
	}
	for (isize i = 0; i < s->entries.count; i++) {
		MapFindResult fr;
		PtrSetEntry<T> *e = &s->entries.data[i];
		e->next = MAP_SENTINEL;
		fr = ptr_set__find_from_entry(s, e);
		if (fr.entry_prev == MAP_SENTINEL) {
			s->hashes[fr.hash_index] = cast(MapIndex)i;
		} else {
			s->entries[fr.entry_prev].next = cast(MapIndex)i;
		}
	}
}

template <typename T>
void ptr_set_reserve(PtrSet<T> *s, isize cap) {
	array_reserve(&s->entries, cap);
	if (s->entries.count*2 < s->hashes.count) {
		return;
	}
	slice_resize(&s->hashes, s->entries.allocator, cap*2);
	ptr_set_reset_entries(s);
}


template <typename T>
void ptr_set_rehash(PtrSet<T> *s, isize new_count) {
	ptr_set_reserve(s, new_count);
}

template <typename T>
gb_inline bool ptr_set_exists(PtrSet<T> *s, T ptr) {
	isize index = ptr_set__find(s, ptr).entry_index;
	return index != MAP_SENTINEL;
}

template <typename T>
gb_inline isize ptr_entry_index(PtrSet<T> *s, T ptr) {
	isize index = ptr_set__find(s, ptr).entry_index;
	if (index != MAP_SENTINEL) {
		return index;
	}
	return -1;
}

// Returns true if it already exists
template <typename T>
T ptr_set_add(PtrSet<T> *s, T ptr) {
	MapIndex index;
	MapFindResult fr;
	if (s->hashes.count == 0) {
		ptr_set_grow(s);
	}
	fr = ptr_set__find(s, ptr);
	if (fr.entry_index == MAP_SENTINEL) {
		index = ptr_set__add_entry(s, ptr);
		if (fr.entry_prev != MAP_SENTINEL) {
			s->entries.data[fr.entry_prev].next = index;
		} else {
			s->hashes.data[fr.hash_index] = index;
		}
	}
	if (ptr_set__full(s)) {
		ptr_set_grow(s);
	}
	return ptr;
}

template <typename T>
bool ptr_set_update(PtrSet<T> *s, T ptr) { // returns true if it previously existsed
	bool exists = false;
	MapIndex index;
	MapFindResult fr;
	if (s->hashes.count == 0) {
		ptr_set_grow(s);
	}
	fr = ptr_set__find(s, ptr);
	if (fr.entry_index != MAP_SENTINEL) {
		exists = true;
	} else {
		index = ptr_set__add_entry(s, ptr);
		if (fr.entry_prev != MAP_SENTINEL) {
			s->entries.data[fr.entry_prev].next = index;
		} else {
			s->hashes.data[fr.hash_index] = index;
		}
	}
	if (ptr_set__full(s)) {
		ptr_set_grow(s);
	}
	return exists;
}



template <typename T>
void ptr_set__erase(PtrSet<T> *s, MapFindResult fr) {
	MapFindResult last;
	if (fr.entry_prev == MAP_SENTINEL) {
		s->hashes.data[fr.hash_index] = s->entries.data[fr.entry_index].next;
	} else {
		s->entries.data[fr.entry_prev].next = s->entries.data[fr.entry_index].next;
	}
	if (cast(isize)fr.entry_index == s->entries.count-1) {
		array_pop(&s->entries);
		return;
	}
	s->entries.data[fr.entry_index] = s->entries.data[s->entries.count-1];
	last = ptr_set__find(s, s->entries.data[fr.entry_index].ptr);
	if (last.entry_prev != MAP_SENTINEL) {
		s->entries.data[last.entry_prev].next = fr.entry_index;
	} else {
		s->hashes.data[last.hash_index] = fr.entry_index;
	}
}

template <typename T>
void ptr_set_remove(PtrSet<T> *s, T ptr) {
	MapFindResult fr = ptr_set__find(s, ptr);
	if (fr.entry_index != MAP_SENTINEL) {
		ptr_set__erase(s, fr);
	}
}

template <typename T>
gb_inline void ptr_set_clear(PtrSet<T> *s) {
	array_clear(&s->entries);
	for (isize i = 0; i < s->hashes.count; i++) {
		s->hashes.data[i] = MAP_SENTINEL;
	}
}
