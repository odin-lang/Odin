template <typename T>
struct MPMCQueueNode {
	std::atomic<isize> idx;
	T                  data;
};

template <typename T>
struct MPMCQueueNodeNonAtomic {
	isize idx;
	T     data;
};

typedef char CacheLinePad[64];

// Multiple Producer Multiple Consumer Queue
template <typename T>
struct MPMCQueue {
	CacheLinePad pad0;
	isize mask;
	Array<MPMCQueueNode<T>> buffer;
	BlockingMutex mutex;
	std::atomic<isize> count;

	CacheLinePad pad1;
	std::atomic<isize> head_idx;

	CacheLinePad pad2;
	std::atomic<isize> tail_idx;

	CacheLinePad pad3;
};


template <typename T>
void mpmc_init(MPMCQueue<T> *q, gbAllocator a, isize size) {
	size = gb_max(size, 8);
	size = next_pow2_isize(size);
	GB_ASSERT(gb_is_power_of_two(size));

	mutex_init(&q->mutex);
	q->mask = size-1;
	array_init(&q->buffer, a, size);

	// NOTE(bill): pretend it's not atomic for performance
	auto *raw_data = cast(MPMCQueueNodeNonAtomic<T> *)q->buffer.data;
	for (isize i = 0; i < size; i += 8) {
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
void mpmc_destroy(MPMCQueue<T> *q) {
	mutex_destroy(&q->mutex);
	gb_free(q->buffer.allocator, q->buffer.data);
}


template <typename T>
isize mpmc_enqueue(MPMCQueue<T> *q, T const &data) {
	if (q->mask == 0) {
		return -1;
	}

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
				return q->count.fetch_add(1, std::memory_order_release);
			}
		} else if (diff < 0) {
			mutex_lock(&q->mutex);
			isize old_size = q->buffer.count;
			isize new_size = old_size*2;
			array_resize(&q->buffer, new_size);
			if (q->buffer.data == nullptr) {
				GB_PANIC("Unable to resize enqueue: %td -> %td", old_size, new_size);
				mutex_unlock(&q->mutex);
				return -1;
			}
			// NOTE(bill): pretend it's not atomic for performance
			auto *raw_data = cast(MPMCQueueNodeNonAtomic<T> *)q->buffer.data;
			for (isize i = old_size; i < new_size; i++) {
				raw_data[i].idx = i;
			}
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


template <typename T>
struct MPSCQueueNode {
	std::atomic<MPSCQueueNode<T> *> next;
	T data;
};

template <typename T>
struct MPSCQueue {
	gbAllocator allocator;

	std::atomic<isize> count;
	std::atomic<MPSCQueueNode<T> *> head;
	std::atomic<MPSCQueueNode<T> *> tail;
};

template <typename T>
void mpsc_init(MPSCQueue<T> *q, gbAllocator a) {
	using Node = MPSCQueueNode<T>;

	q->allocator = a;
	Node *front = cast(Node *)gb_alloc_align(q->allocator, gb_size_of(Node), 64);
	front->next.store(nullptr, std::memory_order_relaxed);
	q->head.store(front, std::memory_order_relaxed);
	q->tail.store(front, std::memory_order_relaxed);
}


template <typename T>
isize mpsc_enqueue(MPSCQueue<T> *q, T const &value) {
	using Node = MPSCQueueNode<T>;

	Node *node = cast(Node *)gb_alloc_align(q->allocator, gb_size_of(Node), 64);
	node->data = value;
	node->next.store(nullptr, std::memory_order_relaxed);

	auto *prev_head = q->head.exchange(node, std::memory_order_acq_rel);
	prev_head->next.store(node, std::memory_order_release);
	return q->count.fetch_add(1, std::memory_order_release);
}

template <typename T>
bool mpsc_dequeue(MPSCQueue<T> *q, T *value_) {
	auto *tail = q->tail.load(std::memory_order_relaxed);
	auto *next = tail->next.load(std::memory_order_acquire);
	if (next == nullptr) {
		return false;
	}

	if (value_) *value_ = next->data;
	q->tail.store(next, std::memory_order_release);
	q->count.fetch_sub(1, std::memory_order_release);
	gb_free(q->allocator, tail);
	return true;
}


template <typename T>
void mpsc_destroy(MPSCQueue<T> *q) {
	T output = {};
	while (mpsc_dequeue(q, &output)) {
		// okay
	}
	auto *front = q->head.load(std::memory_order_relaxed);
	gb_free(q->allocator, front);
}

