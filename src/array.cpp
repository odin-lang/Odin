#define ARRAY_GROW_FORMULA(x) (gb_max(((x)+1)*3 >> 1, 8))
GB_STATIC_ASSERT(ARRAY_GROW_FORMULA(0) > 0);

template <typename T>
struct Array {
	gbAllocator allocator;
	T *         data;
	isize       count;
	isize       capacity;

	T &operator[](isize index) {
		#if !defined(NO_ARRAY_BOUNDS_CHECK)
			GB_ASSERT_MSG(cast(usize)index < cast(usize)count, "Index %td is out of bounds ranges 0..<%td", index, count);
		#endif
		return data[index];
	}

	T const &operator[](isize index) const {
		#if !defined(NO_ARRAY_BOUNDS_CHECK)
			GB_ASSERT_MSG(cast(usize)index < cast(usize)count, "Index %td is out of bounds ranges 0..<%td", index, count);
		#endif
		return data[index];
	}
};

template <typename T> gb_internal void     array_init          (Array<T> *array, gbAllocator const &a);
template <typename T> gb_internal void     array_init          (Array<T> *array, gbAllocator const &a, isize count);
template <typename T> gb_internal void     array_init          (Array<T> *array, gbAllocator const &a, isize count, isize capacity);
template <typename T> gb_internal Array<T> array_make          (gbAllocator const &a);
template <typename T> gb_internal Array<T> array_make          (gbAllocator const &a, isize count);
template <typename T> gb_internal Array<T> array_make          (gbAllocator const &a, isize count, isize capacity);
template <typename T> gb_internal Array<T> array_make_from_ptr (T *data, isize count, isize capacity);
template <typename T> gb_internal void     array_free          (Array<T> *array);
template <typename T> gb_internal void     array_add           (Array<T> *array, T const &t);
template <typename T> gb_internal T *      array_add_and_get   (Array<T> *array);
template <typename T> gb_internal void     array_add_elems     (Array<T> *array, T const *elems, isize elem_count);
template <typename T> gb_internal T        array_pop           (Array<T> *array);
template <typename T> gb_internal void     array_clear         (Array<T> *array);
template <typename T> gb_internal void     array_reserve       (Array<T> *array, isize capacity);
template <typename T> gb_internal void     array_resize        (Array<T> *array, isize count);
template <typename T> gb_internal void     array_set_capacity  (Array<T> *array, isize capacity);
template <typename T> gb_internal Array<T> array_slice         (Array<T> const &array, isize lo, isize hi);
template <typename T> gb_internal Array<T> array_clone         (gbAllocator const &a, Array<T> const &array);

template <typename T> gb_internal void array_ordered_remove  (Array<T> *array, isize index);
template <typename T> gb_internal void array_unordered_remove(Array<T> *array, isize index);

template <typename T> gb_internal void array_copy(Array<T> *array, Array<T> const &data, isize offset);
template <typename T> gb_internal void array_copy(Array<T> *array, Array<T> const &data, isize offset, isize count);

template <typename T> gb_internal T *array_end_ptr(Array<T> *array);


template <typename T>
gb_internal void array_sort(Array<T> &array, gbCompareProc compare_proc) {
	gb_sort_array(array.data, array.count, compare_proc);
}



template <typename T>
struct Slice {
	T *data;
	isize count;

	gb_inline T &operator[](isize index) {
		#if !defined(NO_ARRAY_BOUNDS_CHECK)
			GB_ASSERT_MSG(cast(usize)index < cast(usize)count, "Index %td is out of bounds ranges 0..<%td", index, count);
		#endif
		return data[index];
	}

	gb_inline T const &operator[](isize index) const {
		#if !defined(NO_ARRAY_BOUNDS_CHECK)
			GB_ASSERT_MSG(cast(usize)index < cast(usize)count, "Index %td is out of bounds ranges 0..<%td", index, count);
		#endif
		return data[index];
	}
};

template <typename T> gb_internal Slice<T> slice_from_array(Array<T> const &a);



template <typename T>
gb_internal Slice<T> slice_make(gbAllocator const &allocator, isize count) {
	GB_ASSERT(count >= 0);
	Slice<T> s = {};
	s.data = gb_alloc_array(allocator, T, count);
	if (count > 0) {
		GB_ASSERT(s.data != nullptr);
	}
	s.count = count;
	return s;
}

template <typename T>
gb_internal void slice_init(Slice<T> *s, gbAllocator const &allocator, isize count) {
	GB_ASSERT(count >= 0);
	s->data = gb_alloc_array(allocator, T, count);
	if (count > 0) {
		GB_ASSERT(s->data != nullptr);
	}
	s->count = count;
}

template <typename T>
gb_internal void slice_free(Slice<T> *s, gbAllocator const &allocator) {
	gb_free(allocator, s->data);
}

template <typename T>
gb_internal void slice_resize(Slice<T> *s, gbAllocator const &allocator, isize new_count) {
	resize_array_raw(&s->data, allocator, s->count, new_count);
	s->count = new_count;
}


template <typename T>
gb_internal Slice<T> slice_from_array(Array<T> const &a) {
	return {a.data, a.count};
}
template <typename T>
gb_internal Slice<T> slice_array(Array<T> const &array, isize lo, isize hi) {
	GB_ASSERT(0 <= lo && lo <= hi && hi <= array.count);
	Slice<T> out = {};
	isize len = hi-lo;
	if (len > 0) {
		out.data = array.data+lo;
		out.count = len;
	}
	return out;
}


template <typename T>
gb_internal Slice<T> slice_clone(gbAllocator const &allocator, Slice<T> const &a) {
	T *data = cast(T *)gb_alloc_copy_align(allocator, a.data, a.count*gb_size_of(T), gb_align_of(T));
	return {data, a.count};
}

template <typename T>
gb_internal Slice<T> slice_clone_from_array(gbAllocator const &allocator, Array<T> const &a) {
	auto c = array_clone(allocator, a);
	return {c.data, c.count};
}


template <typename T>
gb_internal void slice_copy(Slice<T> *slice, Slice<T> const &data) {
	isize n = gb_min(slice->count, data.count);
	gb_memmove(slice->data, data.data, gb_size_of(T)*n);
}
template <typename T>
gb_internal void slice_copy(Slice<T> *slice, Slice<T> const &data, isize offset) {
	isize n = gb_clamp(slice->count-offset, 0, data.count);
	gb_memmove(slice->data+offset, data.data, gb_size_of(T)*n);
}
template <typename T>
gb_internal void slice_copy(Slice<T> *slice, Slice<T> const &data, isize offset, isize count) {
	isize n = gb_clamp(slice->count-offset, 0, gb_min(data.count, count));
	gb_memmove(slice->data+offset, data.data, gb_size_of(T)*n);
}



template <typename T>
gb_internal gb_inline Slice<T> slice(Slice<T> const &array, isize lo, isize hi) {
	GB_ASSERT(0 <= lo && lo <= hi && hi <= array.count);
	Slice<T> out = {};
	isize len = hi-lo;
	if (len > 0) {
		out.data = array.data+lo;
		out.count = len;
	}
	return out;
}
template <typename T>
gb_internal gb_inline Slice<T> slice(Array<T> const &array, isize lo, isize hi) {
	GB_ASSERT(0 <= lo && lo <= hi && hi <= array.count);
	Slice<T> out = {};
	isize len = hi-lo;
	if (len > 0) {
		out.data = array.data+lo;
		out.count = len;
	}
	return out;
}


template <typename T>
gb_internal void slice_ordered_remove(Slice<T> *array, isize index) {
	GB_ASSERT(0 <= index && index < array->count);

	isize bytes = gb_size_of(T) * (array->count-(index+1));
	gb_memmove(array->data+index, array->data+index+1, bytes);
	array->count -= 1;
}

template <typename T>
gb_internal void slice_unordered_remove(Slice<T> *array, isize index) {
	GB_ASSERT(0 <= index && index < array->count);

	isize n = array->count-1;
	if (index != n) {
		gb_memmove(array->data+index, array->data+n, gb_size_of(T));
	}
	array->count -= 1;
}


template <typename T>
gb_internal void array_copy(Array<T> *array, Array<T> const &data, isize offset) {
	gb_memmove(array->data+offset, data.data, gb_size_of(T)*data.count);
}
template <typename T>
gb_internal void array_copy(Array<T> *array, Array<T> const &data, isize offset, isize count) {
	gb_memmove(array->data+offset, data.data, gb_size_of(T)*gb_min(data.count, count));
}



template <typename T>
gb_internal T *array_end_ptr(Array<T> *array) {
	if (array->count > 0) {
		return &array->data[array->count-1];
	}
	return nullptr;
}


template <typename T>
gb_internal gb_inline void array_init(Array<T> *array, gbAllocator const &a) {
	isize cap = ARRAY_GROW_FORMULA(0);
	array_init(array, a, 0, cap);
}

template <typename T>
gb_internal gb_inline void array_init(Array<T> *array, gbAllocator const &a, isize count) {
	array_init(array, a, count, count);
}

template <typename T>
gb_internal gb_inline void array_init(Array<T> *array, gbAllocator const &a, isize count, isize capacity) {
	array->allocator = a;
	array->data = nullptr;
	if (capacity > 0) {
		array->data = gb_alloc_array(a, T, capacity);
	}
	array->count = count;
	array->capacity = capacity;
}



template <typename T>
gb_internal gb_inline Array<T> array_make_from_ptr(T *data, isize count, isize capacity) {
	Array<T> a = {0};
	a.data = data;
	a.count = count;
	a.capacity = capacity;
	return a;
}


template <typename T>
gb_internal gb_inline Array<T> array_make(gbAllocator const &a) {
	isize capacity = ARRAY_GROW_FORMULA(0);
	Array<T> array = {};
	array.allocator = a;
	array.data = gb_alloc_array(a, T, capacity);
	array.count = 0;
	array.capacity = capacity;
	return array;
}
template <typename T>
gb_internal gb_inline Array<T> array_make(gbAllocator const &a, isize count) {
	Array<T> array = {};
	array.allocator = a;
	array.data = gb_alloc_array(a, T, count);
	array.count = count;
	array.capacity = count;
	return array;
}
template <typename T>
gb_internal gb_inline Array<T> array_make(gbAllocator const &a, isize count, isize capacity) {
	Array<T> array = {};
	array.allocator = a;
	array.data = gb_alloc_array(a, T, capacity);
	array.count = count;
	array.capacity = capacity;
	return array;
}



template <typename T>
gb_internal gb_inline void array_free(Array<T> *array) {
	if (array->allocator.proc != nullptr) {
		gb_free(array->allocator, array->data);
	}
	array->count = 0;
	array->capacity = 0;
}

template <typename T>
gb_internal void array__grow(Array<T> *array, isize min_capacity) {
	isize new_capacity = ARRAY_GROW_FORMULA(array->capacity);
	if (new_capacity < min_capacity) {
		new_capacity = min_capacity;
	}
	array_set_capacity(array, new_capacity);
}

template <typename T>
gb_internal void array_add(Array<T> *array, T const &t) {
	if (array->capacity < array->count+1) {
		array__grow(array, 0);
	}
	array->data[array->count] = t;
	array->count++;
}

gb_internal void array_add(Array<char const *> *array, char const *t) {
	if (array->capacity < array->count+1) {
		array__grow(array, 0);
	}
	array->data[array->count] = t;
	array->count++;
}

template <typename T>
gb_internal T *array_add_and_get(Array<T> *array) {
	if (array->count < array->capacity) {
		return &array->data[array->count++];
	}
	if (array->capacity < array->count+1) {
		array__grow(array, 0);
	}
	return &array->data[array->count++];
}


template <typename T>
gb_internal void array_add_elems(Array<T> *array, T const *elems, isize elem_count) {
	GB_ASSERT(elem_count >= 0);
	if (array->capacity < array->count+elem_count) {
		array__grow(array, array->count+elem_count);
	}
	gb_memmove(array->data + array->count, elems, elem_count * gb_size_of(T));
	array->count += elem_count;
}


template <typename T>
gb_internal gb_inline T array_pop(Array<T> *array) {
	GB_ASSERT(array->count > 0);
	array->count--;
	return array->data[array->count];
}

template <typename T>
gb_internal void array_clear(Array<T> *array) {
	array->count = 0;
}

template <typename T>
gb_internal void array_reserve(Array<T> *array, isize capacity) {
	if (array->capacity < capacity) {
		array_set_capacity(array, capacity);
	}
}

template <typename T>
gb_internal void array_resize(Array<T> *array, isize count) {
	if (array->capacity < count) {
		array__grow(array, count);
	}
	array->count = count;
}

template <typename T>
gb_internal void array_set_capacity(Array<T> *array, isize capacity) {
	if (capacity == array->capacity) {
		return;
	}

	if (capacity < array->count) {
		array_resize(array, capacity);
	}

	isize old_size = array->capacity * gb_size_of(T);
	isize new_size = capacity * gb_size_of(T);
	T *new_data = nullptr;

	// NOTE(bill): try gb_resize_align first, and then fallback to alloc+memmove+free
	new_data = cast(T *)gb_resize_align(array->allocator, array->data, old_size, new_size, gb_align_of(T));
	if (new_data == nullptr) {
		if (capacity > 0) {
			new_data = gb_alloc_array(array->allocator, T, capacity);
			GB_ASSERT(new_data != nullptr);
			gb_memmove(new_data, array->data, old_size);
		}
		gb_free(array->allocator, array->data);
	}
	array->data = new_data;
	array->capacity = capacity;
}


template <typename T>
gb_internal gb_inline Array<T> array_slice(Array<T> const &array, isize lo, isize hi) {
	GB_ASSERT(0 <= lo && lo <= hi && hi <= array.count);
	Array<T> out = {};
	isize len = hi-lo;
	if (len > 0) {
		out.data = array.data+lo;
		out.count = len;
		out.capacity = len;
	}
	return out;
}

template <typename T>
gb_internal Array<T> array_clone(gbAllocator const &allocator, Array<T> const &array) {
	auto clone = array_make<T>(allocator, array.count, array.count);
	array_copy(&clone, array, 0);
	return clone;
}


template <typename T>
gb_internal void array_ordered_remove(Array<T> *array, isize index) {
	GB_ASSERT(0 <= index && index < array->count);

	isize bytes = gb_size_of(T) * (array->count-(index+1));
	gb_memmove(array->data+index, array->data+index+1, bytes);
	array->count -= 1;
}

template <typename T>
gb_internal void array_unordered_remove(Array<T> *array, isize index) {
	GB_ASSERT(0 <= index && index < array->count);

	isize n = array->count-1;
	if (index != n) {
		gb_memmove(array->data+index, array->data+n, gb_size_of(T));
	}
	array_pop(array);
}



template <typename T>
gb_internal T *begin(Array<T> &array) {
	return array.data;
}
template <typename T>
gb_internal T const *begin(Array<T> const &array) {
	return array.data;
}
template <typename T>
gb_internal T *end(Array<T> &array) {
	return array.data + array.count;
}
template <typename T>
gb_internal T const *end(Array<T> const &array) {
	return array.data + array.count;
}

template <typename T>
gb_internal T *begin(Slice<T> &array) {
	return array.data;
}
template <typename T>
gb_internal T const *begin(Slice<T> const &array) {
	return array.data;
}
template <typename T>
gb_internal T *end(Slice<T> &array) {
	return array.data + array.count;
}
template <typename T>
gb_internal T const *end(Slice<T> const &array) {
	return array.data + array.count;
}
