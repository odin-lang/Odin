template <typename T>
struct MPSCNode {
	std::atomic<MPSCNode<T> *> next;
	T value;
};

//
// Multiple Producer Single Consumer Lockless Queue
// URL: https://www.1024cores.net
//
template <typename T>
struct MPSCQueue {
	MPSCNode<T> sentinel;
	std::atomic<MPSCNode<T> *> head;
	std::atomic<MPSCNode<T> *> tail;
	std::atomic<isize> count;
};

template <typename T> gb_internal void  mpsc_init   (MPSCQueue<T> *q, gbAllocator const &allocator);
template <typename T> gb_internal void  mpsc_destroy(MPSCQueue<T> *q);
template <typename T> gb_internal isize mpsc_enqueue(MPSCQueue<T> *q, T const &value);
template <typename T> gb_internal bool  mpsc_dequeue(MPSCQueue<T> *q, T *value_);

template <typename T>
gb_internal void mpsc_init(MPSCQueue<T> *q, gbAllocator const &allocator) {
	q->sentinel.next.store(nullptr, std::memory_order_relaxed);
	q->head.store(&q->sentinel, std::memory_order_relaxed);
	q->tail.store(&q->sentinel, std::memory_order_relaxed);
	q->count.store(0, std::memory_order_relaxed);
}

template <typename T>
gb_internal void mpsc_destroy(MPSCQueue<T> *q) {
	GB_ASSERT(q->count.load() == 0);
}

template <typename T>
gb_internal MPSCNode<T> *mpsc_alloc_node(MPSCQueue<T> *q, T const &value) {
	auto new_node = gb_alloc_item(heap_allocator(), MPSCNode<T>);
	new_node->value = value;
	return new_node;
}

template <typename T>
gb_internal void mpsc_free_node(MPSCQueue<T> *q, MPSCNode<T> *node) {
	// TODO(bill): determine a good way to handle the freed nodes rather than letting them leak
}

template <typename T>
gb_internal isize mpsc_enqueue(MPSCQueue<T> *q, MPSCNode<T> *node) {
	node->next.store(nullptr, std::memory_order_relaxed);
	auto prev = q->head.exchange(node, std::memory_order_acq_rel);
	prev->next.store(node, std::memory_order_release);
	isize count = 1 + q->count.fetch_add(1, std::memory_order_relaxed);
	return count;
}

template <typename T>
gb_internal isize mpsc_enqueue(MPSCQueue<T> *q, T const &value) {
	auto node = mpsc_alloc_node(q, value);
	return mpsc_enqueue(q, node);
}


template <typename T>
gb_internal bool mpsc_dequeue(MPSCQueue<T> *q, T *value_) {
	auto tail = q->tail.load(std::memory_order_relaxed);
	auto next = tail->next.load(std::memory_order_relaxed);
	if (next) {
		q->tail.store(next, std::memory_order_relaxed);
		if (value_) *value_ = next->value;
		q->count.fetch_sub(1, std::memory_order_relaxed);
		mpsc_free_node(q, tail);
		return true;
	}
	GB_ASSERT(q->count.load(std::memory_order_acquire) == 0);
	return false;
}

////////////////////////////



#define MPMC_CACHE_LINE_SIZE 64

typedef std::atomic<i32> MPMCQueueAtomicIdx;

// Multiple Producer Multiple Consumer Queue
template <typename T>
struct MPMCQueue {
	static size_t const PAD0_OFFSET = (sizeof(T *) + sizeof(MPMCQueueAtomicIdx *) + sizeof(gbAllocator) + sizeof(BlockingMutex) + sizeof(i32) + sizeof(i32));

	T *                 nodes;
	MPMCQueueAtomicIdx *indices;
	BlockingMutex       mutex;
	MPMCQueueAtomicIdx  count;
	i32                 mask; // capacity-1, because capacity must be a power of 2

	char pad0[(MPMC_CACHE_LINE_SIZE*2 - PAD0_OFFSET) % MPMC_CACHE_LINE_SIZE];
	MPMCQueueAtomicIdx head_idx;

	char pad1[MPMC_CACHE_LINE_SIZE - sizeof(i32)];
	MPMCQueueAtomicIdx tail_idx;
};


gb_internal gbAllocator mpmc_allocator(void) {
	return heap_allocator();
}

gb_internal void mpmc_internal_init_indices(MPMCQueueAtomicIdx *indices, i32 offset, i32 size) {
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
gb_internal void mpmc_init(MPMCQueue<T> *q, isize size_i) {
	if (size_i < 8) {
		size_i = 8;
	}
	GB_ASSERT(size_i < I32_MAX);
	i32 size = cast(i32)size_i;
	size = next_pow2(size);
	GB_ASSERT(gb_is_power_of_two(size));

	q->mask = size-1;
	gbAllocator a = mpmc_allocator();
	q->nodes   = gb_alloc_array(a, T, size);
	q->indices = gb_alloc_array(a, MPMCQueueAtomicIdx, size);

	mpmc_internal_init_indices(q->indices, 0, q->mask+1);
}



template <typename T>
gb_internal void mpmc_destroy(MPMCQueue<T> *q) {
	gbAllocator a = mpmc_allocator();
	gb_free(a, q->nodes);
	gb_free(a, q->indices);
}


template <typename T>
gb_internal bool mpmc_internal_grow(MPMCQueue<T> *q) {
	gbAllocator a = mpmc_allocator();
	mutex_lock(&q->mutex);
	i32 old_size = q->mask+1;
	i32 new_size = old_size*2;
	resize_array_raw(&q->nodes, a, old_size, new_size);
	if (q->nodes == nullptr) {
		GB_PANIC("Unable to resize enqueue: %td -> %td", old_size, new_size);
		mutex_unlock(&q->mutex);
		return false;
	}
	resize_array_raw(&q->indices, a, old_size, new_size);
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
gb_internal i32 mpmc_enqueue(MPMCQueue<T> *q, T const &data) {
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
gb_internal bool mpmc_dequeue(MPMCQueue<T> *q, T *data_) {
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

