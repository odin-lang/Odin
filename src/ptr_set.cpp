typedef u32 PtrSetIndex;

struct PtrSetFindResult {
	PtrSetIndex hash_index;
	PtrSetIndex entry_prev;
	PtrSetIndex entry_index;
};

enum : PtrSetIndex { PTR_SET_SENTINEL = ~(PtrSetIndex)0 };


template <typename T>
struct PtrSetEntry {
	T           ptr;
	PtrSetIndex next;
};

template <typename T>
struct PtrSet {
	Slice<PtrSetIndex>    hashes;
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
	capacity = next_pow2_isize(gb_max(16, capacity));

	slice_init(&s->hashes,  a, capacity);
	array_init(&s->entries, a, 0, capacity);
	for (isize i = 0; i < capacity; i++) {
		s->hashes.data[i] = PTR_SET_SENTINEL;
	}
}

template <typename T>
void ptr_set_destroy(PtrSet<T> *s) {
	slice_free(&s->hashes, s->entries.allocator);
	array_free(&s->entries);
}

template <typename T>
gb_internal PtrSetIndex ptr_set__add_entry(PtrSet<T> *s, T ptr) {
	PtrSetEntry<T> e = {};
	e.ptr = ptr;
	e.next = PTR_SET_SENTINEL;
	array_add(&s->entries, e);
	return cast(PtrSetIndex)(s->entries.count-1);
}


template <typename T>
gb_internal PtrSetFindResult ptr_set__find(PtrSet<T> *s, T ptr) {
	PtrSetFindResult fr = {PTR_SET_SENTINEL, PTR_SET_SENTINEL, PTR_SET_SENTINEL};
	if (s->hashes.count != 0) {
		u64 hash = 0xcbf29ce484222325ull ^ cast(u64)cast(uintptr)ptr;
		u64 n = cast(u64)s->hashes.count;
		fr.hash_index = cast(PtrSetIndex)(hash & (n-1));
		fr.entry_index = s->hashes.data[fr.hash_index];
		while (fr.entry_index != PTR_SET_SENTINEL) {
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
gb_internal PtrSetFindResult ptr_set__find_from_entry(PtrSet<T> *s, PtrSetEntry<T> *e) {
	PtrSetFindResult fr = {PTR_SET_SENTINEL, PTR_SET_SENTINEL, PTR_SET_SENTINEL};
	if (s->hashes.count != 0) {
		u64 hash = 0xcbf29ce484222325ull ^ cast(u64)cast(uintptr)e->ptr;
		u64 n = cast(u64)s->hashes.count;
		fr.hash_index = cast(PtrSetIndex)(hash & (n-1));
		fr.entry_index = s->hashes.data[fr.hash_index];
		while (fr.entry_index != PTR_SET_SENTINEL) {
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
	isize new_count = s->hashes.count*2;
	ptr_set_rehash(s, new_count);
}

template <typename T>
void ptr_set_reset_entries(PtrSet<T> *s) {
	PtrSetIndex i;
	for (i = 0; i < cast(PtrSetIndex)s->hashes.count; i++) {
		s->hashes.data[i] = PTR_SET_SENTINEL;
	}
	for (i = 0; i < cast(PtrSetIndex)s->entries.count; i++) {
		PtrSetFindResult fr;
		PtrSetEntry<T> *e = &s->entries.data[i];
		e->next = PTR_SET_SENTINEL;
		fr = ptr_set__find_from_entry(s, e);
		if (fr.entry_prev == PTR_SET_SENTINEL) {
			s->hashes[fr.hash_index] = i;
		} else {
			s->entries[fr.entry_prev].next = i;
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
	return index != PTR_SET_SENTINEL;
}

// Returns true if it already exists
template <typename T>
T ptr_set_add(PtrSet<T> *s, T ptr) {
	PtrSetIndex index;
	PtrSetFindResult fr;
	if (s->hashes.count == 0) {
		ptr_set_grow(s);
	}
	fr = ptr_set__find(s, ptr);
	if (fr.entry_index == PTR_SET_SENTINEL) {
		index = ptr_set__add_entry(s, ptr);
		if (fr.entry_prev != PTR_SET_SENTINEL) {
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
	PtrSetIndex index;
	PtrSetFindResult fr;
	if (s->hashes.count == 0) {
		ptr_set_grow(s);
	}
	fr = ptr_set__find(s, ptr);
	if (fr.entry_index != PTR_SET_SENTINEL) {
		exists = true;
	} else {
		index = ptr_set__add_entry(s, ptr);
		if (fr.entry_prev != PTR_SET_SENTINEL) {
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
void ptr_set__erase(PtrSet<T> *s, PtrSetFindResult fr) {
	PtrSetFindResult last;
	if (fr.entry_prev == PTR_SET_SENTINEL) {
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
	if (last.entry_prev != PTR_SET_SENTINEL) {
		s->entries.data[last.entry_prev].next = fr.entry_index;
	} else {
		s->hashes.data[last.hash_index] = fr.entry_index;
	}
}

template <typename T>
void ptr_set_remove(PtrSet<T> *s, T ptr) {
	PtrSetFindResult fr = ptr_set__find(s, ptr);
	if (fr.entry_index != PTR_SET_SENTINEL) {
		ptr_set__erase(s, fr);
	}
}

template <typename T>
gb_inline void ptr_set_clear(PtrSet<T> *s) {
	array_clear(&s->entries);
	for (isize i = 0; i < s->hashes.count; i++) {
		s->hashes.data[i] = PTR_SET_SENTINEL;
	}
}
