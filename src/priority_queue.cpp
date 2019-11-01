template <typename T>
struct PriorityQueue {
	Array<T> queue;

	int  (* cmp) (T *q, isize i, isize j);
	void (* swap)(T *q, isize i, isize j);
};

template <typename T>
bool priority_queue_shift_down(PriorityQueue<T> *pq, isize i0, isize n) {
	// O(n log n)
	isize i = i0;
	isize j, j1, j2;
	if (0 > i || i > n) return false;
	for (;;) {
		j1 = 2*i + 1;
		if (0 > j1 || j1 >= n) break;
		j = j1;
		j2 = j1 + 1;
		if (j2 < n && pq->cmp(&pq->queue[0], j2, j1) < 0) {
			j = j2;
		}
		if (pq->cmp(&pq->queue[0], j, i) >= 0) break;

		pq->swap(&pq->queue[0], i, j);
		i = j;
	}
	return i > i0;
}

template <typename T>
void priority_queue_shift_up(PriorityQueue<T> *pq, isize j) {
	while (0 <= j && j < pq->queue.count) {
		isize i = (j-1)/2;
		if (i == j || pq->cmp(&pq->queue[0], j, i) >= 0) {
			break;
		}
		pq->swap(&pq->queue[0], i, j);
		j = i;
	}
}

// NOTE(bill): When an element at index `i0` has changed its value, this will fix the
// the heap ordering. This using a basic "heapsort" with shift up and a shift down parts.
template <typename T>
void priority_queue_fix(PriorityQueue<T> *pq, isize i) {
	if (!priority_queue_shift_down(pq, i, pq->queue.count)) {
		priority_queue_shift_up(pq, i);
	}
}

template <typename T>
void priority_queue_push(PriorityQueue<T> *pq, T const &value) {
	array_add(&pq->queue, value);
	priority_queue_shift_up(pq, pq->queue.count-1);
}

template <typename T>
T priority_queue_pop(PriorityQueue<T> *pq) {
	GB_ASSERT(pq->queue.count > 0);

	isize n = pq->queue.count - 1;
	pq->swap(&pq->queue[0], 0, n);
	priority_queue_shift_down(pq, 0, n);
	return array_pop(&pq->queue);
}


template <typename T>
T priority_queue_remove(PriorityQueue<T> *pq, isize i) {
	GB_ASSERT(0 <= i && i < pq->queue.count);
	isize n = pq->queue.count - 1;
	if (n != i) {
		pq->swap(&pq->queue[0], i, n);
		priority_queue_shift_down(pq, i, n);
		priority_queue_shift_up(pq, i);
	}
	return array_pop(&pq->queue);
}


template <typename T>
PriorityQueue<T> priority_queue_create(Array<T> queue,
                                       int  (* cmp) (T *q, isize i, isize j),
                                       void (* swap)(T *q, isize i, isize j)) {
	PriorityQueue<T> pq = {};
	pq.queue = queue;
	pq.cmp   = cmp;
	pq.swap  = swap;

	isize n = pq.queue.count;
	for (isize i = n/2 - 1; i >= 0; i--) {
		priority_queue_shift_down(&pq, i, n);
	}
	return pq;
}
