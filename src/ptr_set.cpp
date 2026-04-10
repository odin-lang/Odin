enum {PTR_SET_INLINE_CAP = 16};

template <typename T>
struct PtrSet {
	static_assert(TypeIsPointer<T>::value || TypeIsPtrSizedInteger<T>::value, "PtrSet::T must be a pointer");
	static constexpr uintptr TOMBSTONE = ~(uintptr)(0ull);

	T * keys;
	u32 count;
	u32 capacity;
	T   inline_keys[PTR_SET_INLINE_CAP];
};

template <typename T> gb_internal void ptr_set_init   (PtrSet<T> *s, isize capacity = 16);
template <typename T> gb_internal void ptr_set_destroy(PtrSet<T> *s);
template <typename T> gb_internal T    ptr_set_add    (PtrSet<T> *s, T ptr);
template <typename T> gb_internal bool ptr_set_update (PtrSet<T> *s, T ptr); // returns true if it previously existed
template <typename T> gb_internal bool ptr_set_exists (PtrSet<T> *s, T ptr);
template <typename T> gb_internal void ptr_set_remove (PtrSet<T> *s, T ptr);
template <typename T> gb_internal void ptr_set_clear  (PtrSet<T> *s);

#define FOR_PTR_SET(element, set_) for (auto *it = &(set_).keys[0], element = it ? *it : nullptr; (set_).keys != nullptr && it < &(set_).keys[(set_).capacity]; it++) if (element = *it, (*it != nullptr && *it != cast(void *)~(uintptr)(0ull)))

gb_internal gbAllocator ptr_set_allocator(void) {
	// return heap_allocator();
	return permanent_allocator();
}

template <typename T>
gb_internal void ptr_set_init(PtrSet<T> *s, isize capacity) {
	GB_ASSERT(s->keys == nullptr);
	if (capacity != 0) {
		capacity = next_pow2_isize(gb_max(PTR_SET_INLINE_CAP, capacity));
		if (capacity > PTR_SET_INLINE_CAP) {
			s->keys = gb_alloc_array(ptr_set_allocator(), T, capacity);
		} else {
			s->keys = s->inline_keys;
		}
		// This memory will be zeroed, no need to explicitly zero it
	}
	s->count = 0;
	s->capacity = cast(u32)capacity;
}

template <typename T>
gb_internal void ptr_set_destroy(PtrSet<T> *s) {
	if (s->keys != s->inline_keys) {
		gb_free(ptr_set_allocator(), s->keys);
	}
	s->keys = nullptr;
	s->count = 0;
	s->capacity = 0;
}

template <typename T>
gb_internal isize ptr_set__find(PtrSet<T> *s, T ptr) {
	GB_ASSERT(ptr != 0);
	if (s->count != 0) {
		u32 hash = ptr_map_hash_key(ptr);
		usize mask = s->capacity-1;
		usize hash_index = cast(usize)hash & mask;

		for (usize i = 0; i < s->capacity; i++) {
			T key = s->keys[hash_index];
			if (key == ptr) {
				return hash_index;
			} else if (key == 0) {
				return -1;
			}
			hash_index = (hash_index+1)&mask;
		}
	}
	return -1;
}

template <typename T>
gb_internal bool ptr_set__full(PtrSet<T> *s) {
	usize grow_at = s->capacity - (s->capacity>>2);
	return s->count >= grow_at;
}

template <typename T>
gb_internal gb_inline void ptr_set_grow(PtrSet<T> *old_set) {
	if (old_set->capacity == 0) {
		ptr_set_init(old_set);
		return;
	}

	PtrSet<T> new_set = {};
	ptr_set_init(&new_set, gb_max(old_set->capacity<<1, 16));

	FOR_PTR_SET(ptr, *old_set) {
		bool was_new = ptr_set_update(&new_set, ptr);
		GB_ASSERT(!was_new);
	}
	GB_ASSERT(old_set->count == new_set.count);

	ptr_set_destroy(old_set);

	*old_set = new_set;
}


template <typename T>
gb_internal gb_inline bool ptr_set_exists(PtrSet<T> *s, T ptr) {
	return ptr_set__find(s, ptr) >= 0;
}


template <typename T>
gb_internal bool ptr_set_update(PtrSet<T> *s, T ptr) { // returns true if it previously existsed
	if (ptr_set_exists(s, ptr)) {
		return true;
	}

	if (s->keys == nullptr) {
		ptr_set_init(s);
	} else if (ptr_set__full(s)) {
		ptr_set_grow(s);
	}
	GB_ASSERT(s->count < s->capacity);
	GB_ASSERT(s->capacity >= 0);

	usize mask = s->capacity-1;
	u32 hash = ptr_map_hash_key(ptr);
	usize hash_index = (cast(usize)hash) & mask;
	GB_ASSERT(hash_index < s->capacity);
	for (usize i = 0; i < s->capacity; i++) {
		T *key_ptr = &s->keys[hash_index];
		T key = *key_ptr;
		GB_ASSERT(key != ptr);
		if (key == (T)PtrSet<T>::TOMBSTONE || key == 0) {
			*key_ptr = ptr;
			s->count++;
			return false;
		}
		hash_index = (hash_index+1)&mask;
	}

	GB_PANIC("ptr set out of memory");
	return false;
}

template <typename T>
gb_internal bool ptr_set_update_with_mutex(PtrSet<T> *s, T ptr, RWSpinLock *m) { // returns true if it previously existsed
	rwlock_acquire_upgrade(m);
	if (ptr_set_exists(s, ptr)) {
		rwlock_release_upgrade(m);
		return true;
	}

	rwlock_release_upgrade_and_acquire_write(m);
	defer (rwlock_release_write(m));

	if (s->keys == nullptr) {
		ptr_set_init(s);
	} else if (ptr_set__full(s)) {
		ptr_set_grow(s);
	}
	GB_ASSERT(s->count < s->capacity);
	GB_ASSERT(s->capacity >= 0);

	usize mask = s->capacity-1;
	u32 hash = ptr_map_hash_key(ptr);
	usize hash_index = (cast(usize)hash) & mask;
	GB_ASSERT(hash_index < s->capacity);
	for (usize i = 0; i < s->capacity; i++) {
		T *key_ptr = &s->keys[hash_index];
		T key = *key_ptr;
		GB_ASSERT(key != ptr);
		if (key == (T)PtrSet<T>::TOMBSTONE || key == 0) {
			*key_ptr = ptr;
			s->count++;
			return false;
		}
		hash_index = (hash_index+1)&mask;
	}

	GB_PANIC("ptr set out of memory");
	return false;
}

template <typename T>
gb_internal T ptr_set_add(PtrSet<T> *s, T ptr) {
	ptr_set_update(s, ptr);
	return ptr;
}


template <typename T>
gb_internal void ptr_set_remove(PtrSet<T> *s, T ptr) {
	isize index = ptr_set__find(s, ptr);
	if (index < 0) {
		return;
	}

#if 0
	u32 mask = s->capacity-1;
	u32 i = cast(u32)index;
	s->count -= 1;

	for (;;) {
		u32 next = (i + 1) & mask;
		T key = s->keys[next];
		if (key == 0) {
			break;
		}

		u32 natural = ptr_map_hash_key(key) & mask;

		if (((next - natural) & mask) == 0) {
			break;
		}
		s->keys[i] = key;
		i = next;
	}
	s->keys[i] = 0;
#else
	GB_ASSERT(s->count > 0);
	s->keys[index] = (T)PtrSet<T>::TOMBSTONE;
	s->count--;
#endif
}

template <typename T>
gb_internal gb_inline void ptr_set_clear(PtrSet<T> *s) {
	s->count = 0;
	gb_zero_size(s->keys, s->capacity*gb_size_of(T));
}

/*template <typename T>
struct PtrSetIterator {
	PtrSet<T> *set;
	usize index;

	PtrSetIterator<T> &operator++() noexcept {
		for (;;) {
			++index;
			if (set->capacity == index) {
				return *this;
			}
			T key = set->keys[index];
			if (key != 0 && key != (T)PtrSet<T>::TOMBSTONE) {
				return *this;
			}
		}
	}

	bool operator==(PtrSetIterator<T> const &other) const noexcept {
		return this->set == other.set && this->index == other.index;
	}


	operator T *() const {
		return &set->keys[index];
	}
};


template <typename T>
gb_internal PtrSetIterator<T> begin(PtrSet<T> &set) noexcept {
	usize index = 0;
	while (index < set.capacity) {
		T key = set.keys[index];
		if (key != 0 && key != (T)PtrSet<T>::TOMBSTONE) {
			break;
		}
		index++;
	}
	return PtrSetIterator<T>{&set, index};
}
template <typename T>
gb_internal PtrSetIterator<T> end(PtrSet<T> &set) noexcept {
	return PtrSetIterator<T>{&set, set.capacity};
}*/


