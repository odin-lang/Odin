#define ARRAY_GROW_FORMULA(x) (2*(x) + 8)
GB_STATIC_ASSERT(ARRAY_GROW_FORMULA(0) > 0);

#if 1
template <typename T>
struct Array {
	gbAllocator allocator;
	T *         data;
	isize       count;
	isize       capacity;

	T &operator[](isize index) {
		#if !defined(NO_ARRAY_BOUNDS_CHECK)
			GB_ASSERT_MSG(0 <= index && index < count, "Index %td is out of bounds ranges 0..<%td", index, count);
		#endif
		return data[index];
	}

	T const &operator[](isize index) const {
		#if !defined(NO_ARRAY_BOUNDS_CHECK)
			GB_ASSERT_MSG(0 <= index && index < count, "Index %td is out of bounds ranges 0..<%td", index, count);
		#endif
		return data[index];
	}
};

template <typename T> void     array_init          (Array<T> *array, gbAllocator const &a);
template <typename T> void     array_init          (Array<T> *array, gbAllocator const &a, isize count);
template <typename T> void     array_init          (Array<T> *array, gbAllocator const &a, isize count, isize capacity);
template <typename T> Array<T> array_make          (gbAllocator const &a);
template <typename T> Array<T> array_make          (gbAllocator const &a, isize count);
template <typename T> Array<T> array_make          (gbAllocator const &a, isize count, isize capacity);
template <typename T> Array<T> array_make_from_ptr (T *data, isize count, isize capacity);
template <typename T> void     array_free          (Array<T> *array);
template <typename T> void     array_add           (Array<T> *array, T const &t);
template <typename T> void     array_add_elems     (Array<T> *array, T const *elems, isize elem_count);
template <typename T> T        array_pop           (Array<T> *array);
template <typename T> void     array_clear         (Array<T> *array);
template <typename T> void     array_reserve       (Array<T> *array, isize capacity);
template <typename T> void     array_resize        (Array<T> *array, isize count);
template <typename T> void     array_set_capacity  (Array<T> *array, isize capacity);
template <typename T> Array<T> array_slice         (Array<T> const &array, isize lo, isize hi);


template <typename T> void array_ordered_remove  (Array<T> *array, isize index);
template <typename T> void array_unordered_remove(Array<T> *array, isize index);


template <typename T>
void array_copy(Array<T> *array, Array<T> const &data, isize offset) {
	gb_memmove(array->data+offset, data.data, gb_size_of(T)*data.count);
}
template <typename T>
void array_copy(Array<T> *array, Array<T> const &data, isize offset, isize count) {
	gb_memmove(array->data+offset, data.data, gb_size_of(T)*gb_min(data.count, count));
}



template <typename T>
T *array_end_ptr(Array<T> *array) {
	if (array->count > 0) {
		return &array->data[array->count-1];
	}
	return nullptr;
}


template <typename T>
gb_inline void array_init(Array<T> *array, gbAllocator const &a) {
	isize cap = ARRAY_GROW_FORMULA(0);
	array_init(array, a, 0, cap);
}

template <typename T>
gb_inline void array_init(Array<T> *array, gbAllocator const &a, isize count) {
	array_init(array, a, count, count);
}

template <typename T>
gb_inline void array_init(Array<T> *array, gbAllocator const &a, isize count, isize capacity) {
	array->allocator = a;
	array->data = nullptr;
	if (capacity > 0) {
		array->data = gb_alloc_array(a, T, capacity);
	}
	array->count = count;
	array->capacity = capacity;
}



template <typename T>
gb_inline Array<T> array_make_from_ptr(T *data, isize count, isize capacity) {
	Array<T> a = {0};
	a.data = data;
	a.count = count;
	a.capacity = capacity;
	return a;
}


template <typename T>
gb_inline Array<T> array_make(gbAllocator const &a) {
	isize capacity = ARRAY_GROW_FORMULA(0);
	Array<T> array = {};
	array.allocator = a;
	array.data = gb_alloc_array(a, T, capacity);
	array.count = 0;
	array.capacity = capacity;
	return array;
}
template <typename T>
gb_inline Array<T> array_make(gbAllocator const &a, isize count) {
	Array<T> array = {};
	array.allocator = a;
	array.data = gb_alloc_array(a, T, count);
	array.count = count;
	array.capacity = count;
	return array;
}
template <typename T>
gb_inline Array<T> array_make(gbAllocator const &a, isize count, isize capacity) {
	Array<T> array = {};
	array.allocator = a;
	array.data = gb_alloc_array(a, T, capacity);
	array.count = count;
	array.capacity = capacity;
	return array;
}



template <typename T>
gb_inline void array_free(Array<T> *array) {
	if (array->allocator.proc != nullptr) {
		gb_free(array->allocator, array->data);
	}
	array->count = 0;
	array->capacity = 0;
}

template <typename T>
void array__grow(Array<T> *array, isize min_capacity) {
	isize new_capacity = ARRAY_GROW_FORMULA(array->capacity);
	if (new_capacity < min_capacity) {
		new_capacity = min_capacity;
	}
	array_set_capacity(array, new_capacity);
}

template <typename T>
void array_add(Array<T> *array, T const &t) {
	if (array->capacity < array->count+1) {
		array__grow(array, 0);
	}
	array->data[array->count] = t;
	array->count++;
}

template <typename T>
void array_add_elems(Array<T> *array, T const *elems, isize elem_count) {
	GB_ASSERT(elem_count >= 0);
	if (array->capacity < array->count+elem_count) {
		array__grow(array, array->count+elem_count);
	}
	gb_memmove(array->data + array->count, elems, elem_count * gb_size_of(T));
	array->count += elem_count;
}


template <typename T>
gb_inline T array_pop(Array<T> *array) {
	GB_ASSERT(array->count > 0);
	array->count--;
	return array->data[array->count];
}

template <typename T>
void array_clear(Array<T> *array) {
	array->count = 0;
}

template <typename T>
void array_reserve(Array<T> *array, isize capacity) {
	if (array->capacity < capacity) {
		array_set_capacity(array, capacity);
	}
}

template <typename T>
void array_resize(Array<T> *array, isize count) {
	if (array->capacity < count) {
		array__grow(array, count);
	}
	array->count = count;
}

template <typename T>
void array_set_capacity(Array<T> *array, isize capacity) {
	if (capacity == array->capacity) {
		return;
	}

	if (capacity < array->count) {
		array_resize(array, capacity);
	}

	T *new_data = nullptr;
	if (capacity > 0) {
		new_data = gb_alloc_array(array->allocator, T, capacity);
		gb_memmove(new_data, array->data, gb_size_of(T) * array->capacity);
	}
	gb_free(array->allocator, array->data);
	array->data = new_data;
	array->capacity = capacity;
}


template <typename T>
gb_inline Array<T> array_slice(Array<T> const &array, isize lo, isize hi) {
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
void array_ordered_remove(Array<T> *array, isize index) {
	GB_ASSERT(0 <= index && index < array->count);

	isize bytes = gb_size_of(T) * (array->count-(index+1));
	gb_memmove(array->data+index, array->data+index+1, bytes);
	array->count -= 1;
}

template <typename T>
void array_unordered_remove(Array<T> *array, isize index) {
	GB_ASSERT(0 <= index && index < array->count);

	isize n = array->count-1;
	if (index != n) {
		gb_memmove(array->data+index, array->data+n, gb_size_of(T));
	}
	array_pop(array);
}




#endif

#if 0
#define Array(Type_) struct { \
	gbAllocator const &allocator; \
	Type_ *     e; \
	isize       count; \
	isize       capacity; \
}

typedef Array(void) ArrayVoid;

#define array_init_reserve(x_, allocator_, init_capacity_) do { \
	void **e = cast(void **)&((x_)->e); \
	GB_ASSERT((x_) != nullptr); \
	(x_)->allocator = (allocator_); \
	(x_)->count = 0; \
	(x_)->capacity = (init_capacity_); \
	*e = gb_alloc((allocator_), gb_size_of(*(x_)->e)*(init_capacity_)); \
} while (0)

#define array_init_count(x_, allocator_, init_count_) do { \
	void **e = cast(void **)&((x_)->e); \
	GB_ASSERT((x_) != nullptr); \
	(x_)->allocator = (allocator_); \
	(x_)->count = (init_count_); \
	(x_)->capacity = (init_count_); \
	*e = gb_alloc((allocator_), gb_size_of(*(x_)->e)*(init_count_)); \
} while (0)

#define array_init(x_, allocator_)        do { array_init_reserve(x_, allocator_, ARRAY_GROW_FORMULA(0)); } while (0)
#define array_free(x_)                    do { gb_free((x_)->allocator, (x_)->e); } while (0)
#define array_set_capacity(x_, capacity_) do { array__set_capacity((x_), (capacity_), gb_size_of(*(x_)->e)); } while (0)

#define array_grow(x_, min_capacity_) do { \
	isize new_capacity = ARRAY_GROW_FORMULA((x_)->capacity); \
	if (new_capacity < (min_capacity_)) { \
		new_capacity = (min_capacity_); \
	} \
	array_set_capacity(x_, new_capacity); \
} while (0)

#define array_add(x_, item_) do { \
	if ((x_)->capacity < (x_)->count+1) { \
		array_grow(x_, 0); \
	} \
	(x_)->e[(x_)->count++] = item_; \
} while (0)

#define array_pop(x_)   do { GB_ASSERT((x_)->count > 0); (x_)->count--; } while (0)
#define array_clear(x_) do { (x_)->count = 0; } while (0)

#define array_resize(x_, new_count_) do { \
	if ((x_)->capacity < (new_count_)) { \
		array_grow((x_), (new_count_)); \
	} \
	(x_)->count = (new_count_); \
} while (0)

#define array_reserve(x_, new_capacity_) do { \
	if ((x_)->capacity < (new_capacity_)) { \
		array_set_capacity((x_), (new_capacity_)); \
	} \
} while (0)




void array__set_capacity(void *ptr, isize capacity, isize element_size) {
	ArrayVoid *x = cast(ArrayVoid *)ptr;
	GB_ASSERT(ptr != nullptr);

	GB_ASSERT(element_size > 0);

	if (capacity == x->capacity) {
		return;
	}

	if (capacity < x->count) {
		if (x->capacity < capacity) {
			isize new_capacity = ARRAY_GROW_FORMULA(x->capacity);
			if (new_capacity < capacity) {
				new_capacity = capacity;
			}
			array__set_capacity(ptr, new_capacity, element_size);
		}
		x->count = capacity;
	}

	x->e = gb_resize(x->allocator, x->e, element_size*x->capacity, element_size*capacity);
	x->capacity = capacity;
}
#endif

