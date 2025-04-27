template <typename T>
struct PtrSet {
	static_assert(TypeIsPointer<T>::value || TypeIsPtrSizedInteger<T>::value, "PtrSet::T must be a pointer");
	static constexpr uintptr TOMBSTONE = ~(uintptr)(0ull);

	T *   keys;
	usize count;
	usize capacity;
};

template <typename T> gb_internal void ptr_set_init   (PtrSet<T> *s, isize capacity = 16);
template <typename T> gb_internal void ptr_set_destroy(PtrSet<T> *s);
template <typename T> gb_internal T    ptr_set_add    (PtrSet<T> *s, T ptr);
template <typename T> gb_internal bool ptr_set_update (PtrSet<T> *s, T ptr); // returns true if it previously existed
template <typename T> gb_internal bool ptr_set_exists (PtrSet<T> *s, T ptr);
template <typename T> gb_internal void ptr_set_remove (PtrSet<T> *s, T ptr);
template <typename T> gb_internal void ptr_set_clear  (PtrSet<T> *s);

gb_internal gbAllocator ptr_set_allocator(void) {
	return heap_allocator();
}

template <typename T>
gb_internal void ptr_set_init(PtrSet<T> *s, isize capacity) {
	GB_ASSERT(s->keys == nullptr);
	if (capacity != 0) {
		capacity = next_pow2_isize(gb_max(16, capacity));
		s->keys = gb_alloc_array(ptr_set_allocator(), T, capacity);
		// This memory will be zeroed, no need to explicitly zero it
	}
	s->count = 0;
	s->capacity = capacity;
}

template <typename T>
gb_internal void ptr_set_destroy(PtrSet<T> *s) {
	gb_free(ptr_set_allocator(), s->keys);
	s->keys = nullptr;
	s->count = 0;
	s->capacity = 0;
}

template <typename T>
gb_internal isize ptr_set__find(PtrSet<T> *s, T ptr) {
	GB_ASSERT(ptr != 0);
	if (s->count != 0) {
	#if 0
		for (usize i = 0; i < s->capacity; i++) {
			if (s->keys[i] == ptr) {
				return i;
			}
		}
	#else
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
	#endif
	}
	return -1;
}

template <typename T>
gb_internal bool ptr_set__full(PtrSet<T> *s) {
	return 0.75f * s->capacity <= s->count;
}

template <typename T>
gb_internal gb_inline void ptr_set_grow(PtrSet<T> *old_set) {
	if (old_set->capacity == 0) {
		ptr_set_init(old_set);
		return;
	}

	PtrSet<T> new_set = {};
	ptr_set_init(&new_set, gb_max(old_set->capacity<<1, 16));

	for (T ptr : *old_set) {
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
		T *key = &s->keys[hash_index];
		GB_ASSERT(*key != ptr);
		if (*key == (T)PtrSet<T>::TOMBSTONE || *key == 0) {
			*key = ptr;
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
	if (index >= 0) {
		GB_ASSERT(s->count > 0);
		s->keys[index] = (T)PtrSet<T>::TOMBSTONE;
		s->count--;
	}
}

template <typename T>
gb_internal gb_inline void ptr_set_clear(PtrSet<T> *s) {
	s->count = 0;
	gb_zero_size(s->keys, s->capacity*gb_size_of(T));
}

template <typename T>
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
}