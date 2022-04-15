#define MPMC_CACHE_LINE_SIZE 64

typedef std::atomic<i32> MPMCQueueAtomicIdx;

// Multiple Producer Multiple Consumer Queue
template <typename T>
struct MPMCQueue {
	static size_t const PAD0_OFFSET = (sizeof(T *) + sizeof(MPMCQueueAtomicIdx *) + sizeof(gbAllocator) + sizeof(BlockingMutex) + sizeof(i32) + sizeof(i32));

	T *                 nodes;
	MPMCQueueAtomicIdx *indices;
	gbAllocator         allocator;
	BlockingMutex       mutex;
	MPMCQueueAtomicIdx  count;
	i32                 mask; // capacity-1, because capacity must be a power of 2

	char pad0[(MPMC_CACHE_LINE_SIZE*2 - PAD0_OFFSET) % MPMC_CACHE_LINE_SIZE];
	MPMCQueueAtomicIdx head_idx;

	char pad1[MPMC_CACHE_LINE_SIZE - sizeof(i32)];
	MPMCQueueAtomicIdx tail_idx;
};



void mpmc_internal_init_indices(MPMCQueueAtomicIdx *indices, i32 offset, i32 size) {
	GB_ASSERT(offset % 8 == 0);
	GB_ASSERT(size % 8 == 0);

	// NOTE(bill): pretend it's not atomic for performance
	auto *raw_data = cast(i32 *)indices;
	for (i32 i = offset; i < size; i += 8) {
		raw_data[i+0] = i+0;
		raw_data[i+1] = i+1;
		raw_data[i+2] = i+2;
		raw_data[i+3] = i+3;
		raw_data[i+4] = i+4;
		raw_data[i+5] = i+5;
		raw_data[i+6] = i+6;
		raw_data[i+7] = i+7;
	}
}


template <typename T>
void mpmc_init(MPMCQueue<T> *q, gbAllocator a, isize size_i) {
	if (size_i < 8) {
		size_i = 8;
	}
	GB_ASSERT(size_i < I32_MAX);
	i32 size = cast(i32)size_i;
	size = next_pow2(size);
	GB_ASSERT(gb_is_power_of_two(size));

	mutex_init(&q->mutex);
	q->mask = size-1;
	q->allocator = a;
	q->nodes   = gb_alloc_array(a, T, size);
	q->indices = gb_alloc_array(a, MPMCQueueAtomicIdx, size);

	mpmc_internal_init_indices(q->indices, 0, q->mask+1);
}



template <typename T>
void mpmc_destroy(MPMCQueue<T> *q) {
	mutex_destroy(&q->mutex);
	gb_free(q->allocator, q->nodes);
	gb_free(q->allocator, q->indices);
}


template <typename T>
bool mpmc_internal_grow(MPMCQueue<T> *q) {
	mutex_lock(&q->mutex);
	i32 old_size = q->mask+1;
	i32 new_size = old_size*2;
	resize_array_raw(&q->nodes, q->allocator, old_size, new_size);
	if (q->nodes == nullptr) {
		GB_PANIC("Unable to resize enqueue: %td -> %td", old_size, new_size);
		mutex_unlock(&q->mutex);
		return false;
	}
	resize_array_raw(&q->indices, q->allocator, old_size, new_size);
	if (q->indices == nullptr) {
		GB_PANIC("Unable to resize enqueue: %td -> %td", old_size, new_size);
		mutex_unlock(&q->mutex);
		return false;
	}
	mpmc_internal_init_indices(q->indices, old_size, new_size);
	q->mask = new_size-1;
	mutex_unlock(&q->mutex);
	return true;
}

template <typename T>
i32 mpmc_enqueue(MPMCQueue<T> *q, T const &data) {
	GB_ASSERT(q->mask != 0);

	i32 head_idx = q->head_idx.load(std::memory_order_relaxed);

	for (;;) {
		i32 index = head_idx & q->mask;
		auto node = &q->nodes[index];
		auto node_idx_ptr = &q->indices[index];
		i32 node_idx = node_idx_ptr->load(std::memory_order_acquire);
		i32 diff = node_idx - head_idx;

		if (diff == 0) {
			i32 next_head_idx = head_idx+1;
			if (q->head_idx.compare_exchange_weak(head_idx, next_head_idx)) {
				*node = data;
				node_idx_ptr->store(next_head_idx, std::memory_order_release);
				return q->count.fetch_add(1, std::memory_order_release);
			}
		} else if (diff < 0) {
			if (!mpmc_internal_grow(q)) {
				return -1;
			}
		} else {
			head_idx = q->head_idx.load(std::memory_order_relaxed);
		}
	}
}

template <typename T>
bool mpmc_dequeue(MPMCQueue<T> *q, T *data_) {
	if (q->mask == 0) {
		return false;
	}

	i32 tail_idx = q->tail_idx.load(std::memory_order_relaxed);

	for (;;) {
		auto node_ptr = &q->nodes[tail_idx & q->mask];
		auto node_idx_ptr = &q->indices[tail_idx & q->mask];
		i32 node_idx = node_idx_ptr->load(std::memory_order_acquire);
		i32 diff = node_idx - (tail_idx+1);

		if (diff == 0) {
			i32 next_tail_idx = tail_idx+1;
			if (q->tail_idx.compare_exchange_weak(tail_idx, next_tail_idx)) {
				if (data_) *data_ = *node_ptr;
				node_idx_ptr->store(tail_idx + q->mask + 1, std::memory_order_release);
				q->count.fetch_sub(1, std::memory_order_release);
				return true;
			}
		} else if (diff < 0) {
			return false;
		} else {
			tail_idx = q->tail_idx.load(std::memory_order_relaxed);
		}
	}
}

