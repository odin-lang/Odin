template <typename T>
struct MPMCQueueNode {
	std::atomic<i32> idx;
	T                data;
};

template <typename T>
struct MPMCQueueNodeNonAtomic {
	i32 idx;
	T   data;
};

#define MPMC_CACHE_LINE_SIZE 64

// Multiple Producer Multiple Consumer Queue
template <typename T>
struct MPMCQueue {
	static size_t const PAD0_OFFSET = (sizeof(Array<MPMCQueueNode<T>>) + sizeof(BlockingMutex) + sizeof(i32) + sizeof(i32));

	Array<MPMCQueueNode<T>> buffer;
	BlockingMutex mutex;
	std::atomic<i32> count;
	i32 mask;

	char pad0[(MPMC_CACHE_LINE_SIZE*2 - PAD0_OFFSET) % MPMC_CACHE_LINE_SIZE];
	std::atomic<i32> head_idx;

	char pad1[MPMC_CACHE_LINE_SIZE - sizeof(i32)];
	std::atomic<i32> tail_idx;
};


template <typename T>
void mpmc_internal_init_buffer(Array<MPMCQueueNode<T>> *buffer, i32 offset) {
	i32 size = cast(i32)buffer->count;
	GB_ASSERT(offset % 8 == 0);
	GB_ASSERT(size % 8 == 0);

	// NOTE(bill): pretend it's not atomic for performance
	auto *raw_data = cast(MPMCQueueNodeNonAtomic<T> *)buffer->data;
	for (i32 i = offset; i < size; i += 8) {
		raw_data[i+0].idx = i+0;
		raw_data[i+1].idx = i+1;
		raw_data[i+2].idx = i+2;
		raw_data[i+3].idx = i+3;
		raw_data[i+4].idx = i+4;
		raw_data[i+5].idx = i+5;
		raw_data[i+6].idx = i+6;
		raw_data[i+7].idx = i+7;
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
	array_init(&q->buffer, a, size);

	mpmc_internal_init_buffer(&q->buffer, 0);
}



template <typename T>
void mpmc_destroy(MPMCQueue<T> *q) {
	mutex_destroy(&q->mutex);
	gb_free(q->buffer.allocator, q->buffer.data);
}


template <typename T>
i32 mpmc_enqueue(MPMCQueue<T> *q, T const &data) {
	GB_ASSERT(q->mask != 0);

	i32 head_idx = q->head_idx.load(std::memory_order_relaxed);

	for (;;) {
		auto node = &q->buffer.data[head_idx & q->mask];
		i32 node_idx = node->idx.load(std::memory_order_acquire);
		i32 diff = node_idx - head_idx;

		if (diff == 0) {
			i32 next_head_idx = head_idx+1;
			if (q->head_idx.compare_exchange_weak(head_idx, next_head_idx)) {
				node->data = data;
				node->idx.store(next_head_idx, std::memory_order_release);
				return q->count.fetch_add(1, std::memory_order_release);
			}
		} else if (diff < 0) {
			mutex_lock(&q->mutex);
			i32 old_size = cast(i32)q->buffer.count;
			i32 new_size = old_size*2;
			array_resize(&q->buffer, new_size);
			if (q->buffer.data == nullptr) {
				GB_PANIC("Unable to resize enqueue: %td -> %td", old_size, new_size);
				mutex_unlock(&q->mutex);
				return -1;
			}
			// NOTE(bill): pretend it's not atomic for performance
			auto *raw_data = cast(MPMCQueueNodeNonAtomic<T> *)q->buffer.data;
			mpmc_internal_init_buffer(&q->buffer, old_size);
			q->mask = new_size-1;
			mutex_unlock(&q->mutex);
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
		auto node = &q->buffer.data[tail_idx & q->mask];
		i32 node_idx = node->idx.load(std::memory_order_acquire);
		i32 diff = node_idx - (tail_idx+1);

		if (diff == 0) {
			i32 next_tail_idx = tail_idx+1;
			if (q->tail_idx.compare_exchange_weak(tail_idx, next_tail_idx)) {
				if (data_) *data_ = node->data;
				node->idx.store(tail_idx + q->mask + 1, std::memory_order_release);
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

