// thread_pool.cpp

// TODO(bill): make work on MSVC
// #if defined(__SANITIZE_THREAD__) || (defined(__has_feature) && __has_feature(thread_sanitizer))
// #include <sanitizer/tsan_interface.h>
// #define TSAN_RELEASE(addr) __tsan_release(addr)
// #define TSAN_ACQUIRE(addr) __tsan_acquire(addr)
// #else
#define TSAN_RELEASE(addr)
#define TSAN_ACQUIRE(addr)
// #endif

struct WorkerTask;
struct ThreadPool;

gb_global gb_thread_local Thread *current_thread;
gb_internal Thread *get_current_thread(void) {
	return current_thread;
}

gb_internal void thread_pool_init(ThreadPool *pool, isize worker_count, char const *worker_name);
gb_internal void thread_pool_destroy(ThreadPool *pool);
gb_internal bool thread_pool_add_task(ThreadPool *pool, WorkerTaskProc *proc, void *data);
gb_internal void thread_pool_wait(ThreadPool *pool);

enum GrabState {
	Grab_Success = 0,
	Grab_Empty   = 1,
	Grab_Failed  = 2,
};

struct ThreadPool {
	gbAllocator       threads_allocator;
	Slice<Thread>     threads;
	std::atomic<bool> running;

	// NOTE: on separate cache lines, as every task changes `tasks_left`
	alignas(2*GB_CACHE_LINE_SIZE) Futex            tasks_available; // bumped to wake a sleeping worker
	                              std::atomic<i32> sleeping;        // workers asleep on `tasks_available`, or about to be
	alignas(2*GB_CACHE_LINE_SIZE) Futex            tasks_left;
};

// NOTE(bill): how many times an idle worker looks for a task before sleeping, so one adding small tasks
// one after another keeps the workers busy rather than waking one for each
enum { THREAD_POOL_SPIN_COUNT = 64 };

struct alignas(GB_CACHE_LINE_SIZE) TaskGroup {
	Futex tasks_left;
};

gb_internal void thread_pool_task_done(ThreadPool *pool, WorkerTask const &task) {
	if (task.group != nullptr && task.group->tasks_left.fetch_sub(1, std::memory_order_acq_rel) == 1) {
		futex_broadcast(&task.group->tasks_left);
	}
	pool->tasks_left.fetch_sub(1, std::memory_order_release);
}

gb_internal isize current_thread_index(void) {
	return current_thread ? current_thread->idx : 0;
}

gb_internal void thread_pool_init(ThreadPool *pool, isize worker_count, char const *worker_name) {
	pool->threads_allocator = permanent_allocator();
	pool->threads = slice_make_aligned<Thread>(pool->threads_allocator, worker_count + 1, gb_align_of(Thread));

	// NOTE: this needs to be initialized before any thread starts
	pool->running.store(true, std::memory_order_seq_cst);

	// setup the main thread
	thread_init(pool, &pool->threads[0], 0);
	current_thread = &pool->threads[0];

	for_array_off(i, 1, pool->threads) {
		Thread *t = &pool->threads[i];
		thread_init_and_start(pool, t, i);
	}
}

gb_internal void thread_pool_destroy(ThreadPool *pool) {
	pool->running.store(false, std::memory_order_seq_cst);

	for_array_off(i, 1, pool->threads) {
		Thread *t = &pool->threads[i];
		pool->tasks_available.fetch_add(1);
		futex_broadcast(&pool->tasks_available);
		thread_join_and_destroy(t);
	}

	gb_free(pool->threads_allocator, pool->threads.data);
}

TaskRingBuffer *task_ring_grow(TaskRingBuffer *ring, isize bottom, isize top) {
	TaskRingBuffer *new_ring = task_ring_init(ring->size * 2);
	for (isize i = top; i < bottom; i++) {
		new_ring->buffer[i % new_ring->size] = ring->buffer[i % ring->size];
	}
	return new_ring;
}

void thread_pool_queue_push(Thread *thread, WorkerTask task) {
	isize bot                = thread->queue.bottom.load(std::memory_order_relaxed);
	isize top                = thread->queue.top.load(std::memory_order_acquire);
	TaskRingBuffer *cur_ring   = thread->queue.ring.load(std::memory_order_relaxed);

	isize size = bot - top;
	if (size > (cur_ring->size - 1)) {
		// Queue is full
		thread->queue.ring = task_ring_grow(thread->queue.ring, bot, top);
		cur_ring = thread->queue.ring.load(std::memory_order_relaxed);
	}

	cur_ring->buffer[bot % cur_ring->size] = task;
	TSAN_RELEASE(cur_ring->buffer[bot % cur_ring->size]);
	std::atomic_thread_fence(std::memory_order_release);
	thread->queue.bottom.store(bot + 1, std::memory_order_relaxed);

	thread->pool->tasks_left.fetch_add(1, std::memory_order_release);

	// NOTE(bill): one sleeping worker per task; waking them all made a loop adding small tasks mostly
	// wake-ups, as they were back asleep before the next. The fence pairs with the one in the worker loop.
	std::atomic_thread_fence(std::memory_order_seq_cst);
	if (thread->pool->sleeping.load(std::memory_order_relaxed) > 0) {
		thread->pool->tasks_available.fetch_add(1);
		futex_signal(&thread->pool->tasks_available);
	}
}

GrabState thread_pool_queue_take(Thread *thread, WorkerTask *task) {
	isize bot = thread->queue.bottom.load(std::memory_order_relaxed) - 1;
	TaskRingBuffer *cur_ring = thread->queue.ring.load(std::memory_order_relaxed);
	thread->queue.bottom.store(bot, std::memory_order_relaxed);
	std::atomic_thread_fence(std::memory_order_seq_cst);

	isize top = thread->queue.top.load(std::memory_order_relaxed);
	if (top <= bot) {

		// Queue is not empty
		TSAN_ACQUIRE(cur_ring->buffer[bot % cur_ring->size]);
		*task = cur_ring->buffer[bot % cur_ring->size];
		if (top == bot) {
			// Only one entry left in queue
			if (!thread->queue.top.compare_exchange_strong(top, top + 1, std::memory_order_seq_cst, std::memory_order_relaxed)) {
				// Race failed
				thread->queue.bottom.store(bot + 1, std::memory_order_relaxed);
				return Grab_Empty;
			}

			thread->queue.bottom.store(bot + 1, std::memory_order_relaxed);
			return Grab_Success;
		}

		// We got a task without hitting a race
		return Grab_Success;
	} else {
		// Queue is empty
		thread->queue.bottom.store(bot + 1, std::memory_order_relaxed);
		return Grab_Empty;
	}
}

GrabState thread_pool_queue_steal(Thread *thread, WorkerTask *task) {
	isize top = thread->queue.top.load(std::memory_order_acquire);
	std::atomic_thread_fence(std::memory_order_seq_cst);
	isize bot = thread->queue.bottom.load(std::memory_order_acquire);

	GrabState ret = Grab_Empty;
	if (top < bot) {
		// Queue is not empty
		TaskRingBuffer *cur_ring = thread->queue.ring.load(std::memory_order_consume);

		TSAN_ACQUIRE(&cur_ring->buffer[top % cur_ring->size]);
		*task = cur_ring->buffer[top % cur_ring->size];

		if (!thread->queue.top.compare_exchange_strong(top, top + 1, std::memory_order_seq_cst, std::memory_order_relaxed)) {
			// Race failed
			ret = Grab_Failed;
		} else {
			ret = Grab_Success;
		}
	}
	return ret;
}

gb_internal bool thread_pool_queue_has_tasks(Thread *thread) {
	return thread->queue.top.load(std::memory_order_acquire) < thread->queue.bottom.load(std::memory_order_acquire);
}

// Runs a task from another thread's queue; false if none had one
gb_internal bool thread_pool_steal(ThreadPool *pool) {
	usize idx = cast(usize)current_thread->idx;
	for_array(i, pool->threads) {
		idx = (idx + 1) % cast(usize)pool->threads.count;
		Thread *thread = &pool->threads.data[idx];
		if (!thread_pool_queue_has_tasks(thread)) {
			continue;
		}

		WorkerTask task;
		switch (thread_pool_queue_steal(thread, &task)) {
		case Grab_Empty:
			continue;
		case Grab_Success:
			task.do_work(task.data);
			thread_pool_task_done(pool, task);

			if (pool->tasks_left.load(std::memory_order_acquire) == 0) {
				futex_signal(&pool->tasks_left);
			}
			return true;
		case Grab_Failed:
			// NOTE: another thread took it, so there may be more
			return true;
		}
	}
	return false;
}

gb_internal bool thread_pool_add_task(ThreadPool *pool, WorkerTaskProc *proc, void *data) {
	WorkerTask task = {};
	task.do_work = proc;
	task.data = data;
		
	thread_pool_queue_push(current_thread, task);
	return true;
}	

gb_internal bool thread_wait_for_owner(Futex *futex, Footex value, i32 owner) {
	if (futex->load() != value) {
		return true;
	}
	Thread *self = current_thread;
	if (self != nullptr && owner > 0) {
		i32 me = cast(i32)self->idx + 1;
		if (owner == me) {
			return false;
		}
		self->waiting_futex.store(futex);
		self->waiting_value.store(value);
		self->waiting_for.store(owner);

		// NOTE(bill): a thread counts as waiting only while what it waits on is unchanged
		// when it clears its own `waiting_for` only once it has woken
		Slice<Thread> threads = self->pool->threads;
		i32 t = owner;
		for (isize i = 0; i <= threads.count; i++) {
			if (t == me) {
				self->waiting_for.store(0);
				return false;
			}
			Thread *other = &threads[t-1];
			i32 next = other->waiting_for.load();
			Futex *f = other->waiting_futex.load();
			if (next == 0 || f == nullptr || f->load() != other->waiting_value.load()) {
				break;
			}
			t = next;
		}
	}
	while (futex->load() == value) {
		futex_wait(futex, value);
	}
	if (self != nullptr) {
		self->waiting_for.store(0);
	}
	return true;
}

gb_internal void thread_pool_wait(ThreadPool *pool) {
	WorkerTask task;

	while (pool->tasks_left.load(std::memory_order_acquire)) {
		// if we've got tasks on our queue, run them
		while (!thread_pool_queue_take(current_thread, &task)) {
			task.do_work(task.data);
			thread_pool_task_done(pool, task);
		}

		// is this mem-barriered enough?
		// This *must* be executed in this order, so the futex wakes immediately
		// if rem_tasks has changed since we checked last, otherwise the program
		// will permanently sleep
		Footex rem_tasks = pool->tasks_left.load(std::memory_order_acquire);
		if (rem_tasks == 0) {
			return;
		}

		futex_wait(&pool->tasks_left, rem_tasks);
	}
}

gb_internal bool thread_pool_add_task(TaskGroup *group, WorkerTaskProc *proc, void *data) {
	group->tasks_left.fetch_add(1, std::memory_order_relaxed);
	WorkerTask task = {proc, data, group};
	thread_pool_queue_push(current_thread, task);
	return true;
}

gb_internal void thread_pool_wait(TaskGroup *group) {
	ThreadPool *pool = current_thread->pool;
	WorkerTask task;
	for (;;) {
		Footex left = group->tasks_left.load(std::memory_order_acquire);
		if (left == 0) {
			return;
		}
		if (!thread_pool_queue_take(current_thread, &task)) {
			task.do_work(task.data);
			thread_pool_task_done(pool, task);
			if (pool->tasks_left.load(std::memory_order_acquire) == 0) {
				futex_signal(&pool->tasks_left);
			}
			continue;
		}
		if (thread_pool_steal(pool)) {
			continue;
		}
		futex_wait(&group->tasks_left, left);
	}
}

gb_internal THREAD_PROC(thread_pool_thread_proc) {
	WorkerTask task;
	current_thread = thread;
	ThreadPool *pool = current_thread->pool;
	// debugf("worker id: %td\n", current_thread->idx);

	while (pool->running.load(std::memory_order_seq_cst)) {
		// If we've got tasks to process, work through them
		usize finished_tasks = 0;

		while (!thread_pool_queue_take(current_thread, &task)) {
			task.do_work(task.data);
			thread_pool_task_done(pool, task);

			finished_tasks += 1;
		}
		if (finished_tasks > 0 && pool->tasks_left.load(std::memory_order_acquire) == 0) {
			futex_signal(&pool->tasks_left);
		}

		// If there's still work somewhere and we don't have it, steal it
		for (isize spin = 0; spin < THREAD_POOL_SPIN_COUNT; spin++) {
			if (thread_pool_steal(pool)) {
				goto main_loop_continue;
			}
			yield_thread();
		}

		// if we've done all our work, and there's nothing to steal, go to sleep
		{
			Footex epoch = pool->tasks_available.load();
			pool->sleeping.fetch_add(1, std::memory_order_relaxed);
			std::atomic_thread_fence(std::memory_order_seq_cst);

			// NOTE: a task added before `sleeping` was raised woke nobody, so look again
			bool has_tasks = false;
			for (Thread &t : pool->threads) {
				has_tasks |= thread_pool_queue_has_tasks(&t);
			}
			if (!has_tasks && pool->running.load()) {
				futex_wait(&pool->tasks_available, epoch);
			}
			pool->sleeping.fetch_sub(1, std::memory_order_relaxed);
		}

		main_loop_continue:;
	}

	return 0;
}


template <typename T>
struct alignas(2*GB_CACHE_LINE_SIZE) PerThreadArraySlot {
	Array<T> array;
	u8       padding[2*GB_CACHE_LINE_SIZE - gb_size_of(Array<T>)];
};

template <typename T>
struct PerThreadArray {
	Slice<PerThreadArraySlot<T> > slots;
};

template <typename T>
gb_internal void per_thread_array_init(PerThreadArray<T> *a, isize thread_count) {
	isize align = gb_align_of(PerThreadArraySlot<T>);
	a->slots = slice_make_aligned<PerThreadArraySlot<T> >(permanent_allocator(), thread_count, align);
	GB_ASSERT((cast(uintptr)a->slots.data & (align - 1)) == 0);
	for (PerThreadArraySlot<T> &slot : a->slots) {
		array_init(&slot.array, heap_allocator());
	}
}

template <typename T>
gb_internal void per_thread_array_destroy(PerThreadArray<T> *a) {
	for (PerThreadArraySlot<T> &slot : a->slots) {
		array_free(&slot.array);
	}
}

template <typename T>
gb_internal void per_thread_array_add(PerThreadArray<T> *a, T const &value) {
	isize index = current_thread_index();
	GB_ASSERT(0 <= index && index < a->slots.count);
	array_add(&a->slots[index].array, value);
}

template <typename T>
gb_internal isize per_thread_array_count(PerThreadArray<T> *a) {
	isize count = 0;
	for (PerThreadArraySlot<T> &slot : a->slots) {
		count += slot.array.count;
	}
	return count;
}

template <typename T>
gb_internal void per_thread_array_gather(PerThreadArray<T> *a, Array<T> *dst) {
	array_reserve(dst, dst->count + per_thread_array_count(a));
	for (PerThreadArraySlot<T> &slot : a->slots) {
		array_add_elems(dst, slot.array.data, slot.array.count);
		array_clear(&slot.array);
	}
}

gb_global ThreadPool global_thread_pool;

gb_internal bool thread_pool_add_task(WorkerTaskProc *proc, void *data) {
	return thread_pool_add_task(&global_thread_pool, proc, data);
}
gb_internal void thread_pool_wait(void) {
	thread_pool_wait(&global_thread_pool);
}

template <typename T>
struct ThreadPoolChunk {
	T *   items;
	isize count;
	void (*proc)(T *items, isize count);
};

template <typename T>
gb_internal WORKER_TASK_PROC(thread_pool_chunk_worker_proc) {
	ThreadPoolChunk<T> *chunk = cast(ThreadPoolChunk<T> *)data;
	chunk->proc(chunk->items, chunk->count);
	return 0;
}


template <typename T>
struct ThreadPoolChunks {
	TaskGroup                  group;
	Array<ThreadPoolChunk<T> > chunks;
};

template <typename T>
gb_internal void thread_pool_start_chunks(ThreadPoolChunks<T> *c, T *items, isize count, isize chunk_size, void (*proc)(T *items, isize count)) {
	c->chunks = array_make<ThreadPoolChunk<T> >(heap_allocator(), 0, count/chunk_size + 1);
	for (isize i = 0; i < count; i += chunk_size) {
		array_add(&c->chunks, ThreadPoolChunk<T>{items + i, gb_min(chunk_size, count - i), proc});
	}
	for (ThreadPoolChunk<T> &chunk : c->chunks) {
		thread_pool_add_task(&c->group, thread_pool_chunk_worker_proc<T>, &chunk);
	}
}

template <typename T>
gb_internal void thread_pool_wait_chunks(ThreadPoolChunks<T> *c) {
	thread_pool_wait(&c->group);
	array_free(&c->chunks);
}

template <typename T>
gb_internal void thread_pool_for_chunks(T *items, isize count, isize chunk_size, void (*proc)(T *items, isize count)) {
	ThreadPoolChunks<T> c = {};
	thread_pool_start_chunks(&c, items, count, chunk_size, proc);
	thread_pool_wait_chunks(&c);
}
