template <typename T>
struct MPMCQueueNode {
	T data;
	std::atomic<isize> idx;
};

typedef char CacheLinePad[64];

// Multiple Producer Multiple Consumer Queue
template <typename T>
struct MPMCQueue {
	CacheLinePad pad0;
	isize mask;
	Array<MPMCQueueNode<T>> buffer;
	gbMutex mutex;
	std::atomic<isize> count;

	CacheLinePad pad1;
	std::atomic<isize> head_idx;

	CacheLinePad pad2;
	std::atomic<isize> tail_idx;

	CacheLinePad pad3;
};


template <typename T>
void mpmc_init(MPMCQueue<T> *q, gbAllocator a, isize size) {
	size = next_pow2_isize(size);
	GB_ASSERT(gb_is_power_of_two(size));

	gb_mutex_init(&q->mutex);
	q->mask = size-1;
	array_init(&q->buffer, a, size);
	for (isize i = 0; i < size; i++) {
		q->buffer[i].idx.store(i, std::memory_order_relaxed);
	}
}

template <typename T>
void mpmc_destroy(MPMCQueue<T> *q) {
	gb_mutex_destroy(&q->mutex);
	gb_free(q->buffer.allocator, q->buffer.data);
}


template <typename T>
bool mpmc_enqueue(MPMCQueue<T> *q, T const &data) {
	isize head_idx = q->head_idx.load(std::memory_order_relaxed);

	for (;;) {
		auto node = &q->buffer.data[head_idx & q->mask];
		isize node_idx = node->idx.load(std::memory_order_acquire);
		isize diff = node_idx - head_idx;

		if (diff == 0) {
			isize next_head_idx = head_idx+1;
			if (q->head_idx.compare_exchange_weak(head_idx, next_head_idx)) {
				node->data = data;
				node->idx.store(next_head_idx, std::memory_order_release);
				q->count.fetch_add(1, std::memory_order_release);
				return true;
			}
		} else if (diff < 0) {
			gb_mutex_lock(&q->mutex);
			isize old_size = q->buffer.count;
			isize new_size = old_size*2;
			array_resize(&q->buffer, new_size);
			if (q->buffer.data == nullptr) {
				GB_PANIC("Unable to resize enqueue: %td -> %td", old_size, new_size);
				gb_mutex_unlock(&q->mutex);
				return false;
			}
			for (isize i = old_size; i < new_size; i++) {
				q->buffer.data[i].idx.store(i, std::memory_order_relaxed);
			}
			q->mask = new_size-1;
			gb_mutex_unlock(&q->mutex);
		} else {
			head_idx = q->head_idx.load(std::memory_order_relaxed);
		}
	}
}


template <typename T>
bool mpmc_dequeue(MPMCQueue<T> *q, T *data_) {
	isize tail_idx = q->tail_idx.load(std::memory_order_relaxed);

	for (;;) {
		auto node = &q->buffer.data[tail_idx & q->mask];
		isize node_idx = node->idx.load(std::memory_order_acquire);
		isize diff = node_idx - (tail_idx+1);

		if (diff == 0) {
			isize next_tail_idx = tail_idx+1;
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
