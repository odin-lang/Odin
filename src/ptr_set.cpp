struct PtrSetFindResult {
	isize hash_index;
	isize entry_prev;
	isize entry_index;
};


template <typename T>
struct PtrSetEntry {
	T     ptr;
	isize next;
};

template <typename T>
struct PtrSet {
	Array<isize>          hashes;
	Array<PtrSetEntry<T>> entries;
};

template <typename T> void ptr_set_init   (PtrSet<T> *s, gbAllocator a, isize capacity = 16);
template <typename T> void ptr_set_destroy(PtrSet<T> *s);
template <typename T> T    ptr_set_add    (PtrSet<T> *s, T ptr);
template <typename T> bool ptr_set_exists (PtrSet<T> *s, T ptr);
template <typename T> void ptr_set_remove (PtrSet<T> *s, T ptr);
template <typename T> void ptr_set_clear  (PtrSet<T> *s);
template <typename T> void ptr_set_grow   (PtrSet<T> *s);
template <typename T> void ptr_set_rehash (PtrSet<T> *s, isize new_count);


template <typename T>
void ptr_set_init(PtrSet<T> *s, gbAllocator a, isize capacity) {
	array_init(&s->hashes,  a, capacity);
	array_init(&s->entries, a, 0, capacity);
	for (isize i = 0; i < capacity; i++) {
		s->hashes.data[i] = -1;
	}
}

template <typename T>
void ptr_set_destroy(PtrSet<T> *s) {
	array_free(&s->hashes);
	array_free(&s->entries);
}

template <typename T>
gb_internal isize ptr_set__add_entry(PtrSet<T> *s, T ptr) {
	PtrSetEntry<T> e = {};
	e.ptr = ptr;
	e.next = -1;
	array_add(&s->entries, e);
	return s->entries.count-1;
}


template <typename T>
gb_internal PtrSetFindResult ptr_set__find(PtrSet<T> *s, T ptr) {
	PtrSetFindResult fr = {-1, -1, -1};
	if (s->hashes.count > 0) {
		u64 hash = 0xcbf29ce484222325ull ^ cast(u64)cast(uintptr)ptr;
		u64 n = cast(u64)s->hashes.count;
		fr.hash_index = cast(isize)(hash % n);
		fr.entry_index = s->hashes[fr.hash_index];
		while (fr.entry_index >= 0) {
			if (s->entries[fr.entry_index].ptr == ptr) {
				return fr;
			}
			fr.entry_prev = fr.entry_index;
			fr.entry_index = s->entries[fr.entry_index].next;
		}
	}
	return fr;
}

template <typename T>
gb_internal b32 ptr_set__full(PtrSet<T> *s) {
	return 0.75f * s->hashes.count <= s->entries.count;
}

#define PTR_ARRAY_GROW_FORMULA(x) (4*(x) + 7)
GB_STATIC_ASSERT(PTR_ARRAY_GROW_FORMULA(0) > 0);

template <typename T>
gb_inline void ptr_set_grow(PtrSet<T> *s) {
	isize new_count = PTR_ARRAY_GROW_FORMULA(s->entries.count);
	ptr_set_rehash(s, new_count);
}

template <typename T>
void ptr_set_rehash(PtrSet<T> *s, isize new_count) {
	isize i, j;
	PtrSet<T> ns = {};
	ptr_set_init(&ns, s->hashes.allocator);
	array_resize(&ns.hashes, new_count);
	array_reserve(&ns.entries, s->entries.count);
	for (i = 0; i < new_count; i++) {
		ns.hashes[i] = -1;
	}
	for (i = 0; i < s->entries.count; i++) {
		PtrSetEntry<T> *e = &s->entries[i];
		PtrSetFindResult fr;
		if (ns.hashes.count == 0) {
			ptr_set_grow(&ns);
		}
		fr = ptr_set__find(&ns, e->ptr);
		j = ptr_set__add_entry(&ns, e->ptr);
		if (fr.entry_prev < 0) {
			ns.hashes[fr.hash_index] = j;
		} else {
			ns.entries[fr.entry_prev].next = j;
		}
		ns.entries[j].next = fr.entry_index;
		if (ptr_set__full(&ns)) {
			ptr_set_grow(&ns);
		}
	}
	ptr_set_destroy(s);
	*s = ns;
}

template <typename T>
gb_inline bool ptr_set_exists(PtrSet<T> *s, T ptr) {
	isize index = ptr_set__find(s, ptr).entry_index;
	return index >= 0;
}

// Returns true if it already exists
template <typename T>
T ptr_set_add(PtrSet<T> *s, T ptr) {
	isize index;
	PtrSetFindResult fr;
	if (s->hashes.count == 0) {
		ptr_set_grow(s);
	}
	fr = ptr_set__find(s, ptr);
	if (fr.entry_index >= 0) {
		index = fr.entry_index;
	} else {
		index = ptr_set__add_entry(s, ptr);
		if (fr.entry_prev >= 0) {
			s->entries[fr.entry_prev].next = index;
		} else {
			s->hashes[fr.hash_index] = index;
		}
	}
	if (ptr_set__full(s)) {
		ptr_set_grow(s);
	}
	return ptr;
}


template <typename T>
void ptr_set__erase(PtrSet<T> *s, PtrSetFindResult fr) {
	PtrSetFindResult last;
	if (fr.entry_prev < 0) {
		s->hashes[fr.hash_index] = s->entries[fr.entry_index].next;
	} else {
		s->entries[fr.entry_prev].next = s->entries[fr.entry_index].next;
	}
	if (fr.entry_index == s->entries.count-1) {
		array_pop(&s->entries);
		return;
	}
	s->entries[fr.entry_index] = s->entries[s->entries.count-1];
	last = ptr_set__find(s, s->entries[fr.entry_index].ptr);
	if (last.entry_prev >= 0) {
		s->entries[last.entry_prev].next = fr.entry_index;
	} else {
		s->hashes[last.hash_index] = fr.entry_index;
	}
}

template <typename T>
void ptr_set_remove(PtrSet<T> *s, T ptr) {
	PtrSetFindResult fr = ptr_set__find(s, ptr);
	if (fr.entry_index >= 0) {
		ptr_set__erase(s, fr);
	}
}

template <typename T>
gb_inline void ptr_set_clear(PtrSet<T> *s) {
	array_clear(&s->hashes);
	array_clear(&s->entries);
}
