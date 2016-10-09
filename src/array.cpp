#define ARRAY_GROW_FORMULA(x) (2*(x) + 8)

template <typename T>
struct Array {
	gbAllocator allocator;
	T *data;
	isize count;
	isize capacity;

	T &operator[](isize index) {
		GB_ASSERT_MSG(0 <= index && index < count, "Index out of bounds");
		return data[index];
	}

	T const &operator[](isize index) const {
		GB_ASSERT_MSG(0 <= index && index < count, "Index out of bounds");
		return data[index];
	}
};

template <typename T> void     array_init        (Array<T> *array, gbAllocator a, isize init_capacity = 8);
template <typename T> Array<T> array_make        (T *data, isize count, isize capacity);
template <typename T> void     array_free        (Array<T> *array);
template <typename T> void     array_add         (Array<T> *array, T const &t);
template <typename T> T        array_pop         (Array<T> *array);
template <typename T> void     array_clear       (Array<T> *array);
template <typename T> void     array_reserve     (Array<T> *array, isize capacity);
template <typename T> void     array_resize      (Array<T> *array, isize count);
template <typename T> void     array_set_capacity(Array<T> *array, isize capacity);


template <typename T>
void array_init(Array<T> *array, gbAllocator a, isize init_capacity) {
	array->allocator = a;
	array->data = gb_alloc_array(a, T, init_capacity);
	array->count = 0;
	array->capacity = init_capacity;
}

template <typename T>
Array<T> array_make(T *data, isize count, isize capacity) {
	Array<T> a = {};
	a.data = data;
	a.count = count;
	a.capacity = capacity;
	return a;
}


template <typename T>
void array_free(Array<T> *array) {
	if (array->allocator.proc != NULL) {
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
T array_pop(Array<T> *array) {
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

	T *new_data = NULL;
	if (capacity > 0) {
		new_data = gb_alloc_array(array->allocator, T, capacity);
		gb_memmove(new_data, array->data, gb_size_of(T) * array->capacity);
	}
	gb_free(array->allocator, array->data);
	array->data = new_data;
	array->capacity = capacity;
}



