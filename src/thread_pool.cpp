// thread_pool.cpp

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

	Futex tasks_available;
	Futex tasks_left;
};

gb_internal isize current_thread_index(void) {
	return current_thread ? current_thread->idx : 0;
}

gb_internal void thread_pool_init(ThreadPool *pool, isize worker_count, char const *worker_name) {
	pool->threads_allocator = permanent_allocator();
	slice_init(&pool->threads, pool->threads_allocator, worker_count + 1);

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
		pool->tasks_available.fetch_add(1, std::memory_order_acquire);
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
	std::atomic_thread_fence(std::memory_order_release);
	thread->queue.bottom.store(bot + 1, std::memory_order_relaxed);

	thread->pool->tasks_left.fetch_add(1, std::memory_order_release);
	thread->pool->tasks_available.fetch_add(1, std::memory_order_relaxed);
	futex_broadcast(&thread->pool->tasks_available);
}

GrabState thread_pool_queue_take(Thread *thread, WorkerTask *task) {
	isize bot = thread->queue.bottom.load(std::memory_order_relaxed) - 1;
	TaskRingBuffer *cur_ring = thread->queue.ring.load(std::memory_order_relaxed);
	thread->queue.bottom.store(bot, std::memory_order_relaxed);
	std::atomic_thread_fence(std::memory_order_seq_cst);

	isize top = thread->queue.top.load(std::memory_order_relaxed);
	if (top <= bot) {

		// Queue is not empty
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

gb_internal bool thread_pool_add_task(ThreadPool *pool, WorkerTaskProc *proc, void *data) {
	WorkerTask task = {};
	task.do_work = proc;
	task.data = data;
		
	thread_pool_queue_push(current_thread, task);
	return true;
}	

gb_internal void thread_pool_wait(ThreadPool *pool) {
	WorkerTask task;

	while (pool->tasks_left.load(std::memory_order_acquire)) {
		// if we've got tasks on our queue, run them
		while (!thread_pool_queue_take(current_thread, &task)) {
			task.do_work(task.data);
			pool->tasks_left.fetch_sub(1, std::memory_order_release);
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

gb_internal THREAD_PROC(thread_pool_thread_proc) {
	WorkerTask task;
	current_thread = thread;
	ThreadPool *pool = current_thread->pool;
	// debugf("worker id: %td\n", current_thread->idx);

	while (pool->running.load(std::memory_order_seq_cst)) {
		// If we've got tasks to process, work through them
		usize finished_tasks = 0;
		i32 state;

		while (!thread_pool_queue_take(current_thread, &task)) {
			task.do_work(task.data);
			pool->tasks_left.fetch_sub(1, std::memory_order_release);

			finished_tasks += 1;
		}
		if (finished_tasks > 0 && pool->tasks_left.load(std::memory_order_acquire) == 0) {
			futex_signal(&pool->tasks_left);
		}

		// If there's still work somewhere and we don't have it, steal it
		if (pool->tasks_left.load(std::memory_order_acquire)) {
			usize idx = cast(usize)current_thread->idx;
			for_array(i, pool->threads) {
				if (pool->tasks_left.load(std::memory_order_acquire) == 0) {
					break;
				}

				idx = (idx + 1) % cast(usize)pool->threads.count;

				Thread *thread = &pool->threads.data[idx];
				WorkerTask task;

				GrabState ret = thread_pool_queue_steal(thread, &task);
				switch (ret) {
				case Grab_Empty:
					continue;
				case Grab_Success:
					task.do_work(task.data);
					pool->tasks_left.fetch_sub(1, std::memory_order_release);

					if (pool->tasks_left.load(std::memory_order_acquire) == 0) {
						futex_signal(&pool->tasks_left);
					}

					/*fallthrough*/
				case Grab_Failed:
					goto main_loop_continue;
				}
			}
		}

		// if we've done all our work, and there's nothing to steal, go to sleep
		state = pool->tasks_available.load(std::memory_order_acquire);
		if (!pool->running) { break; }
		futex_wait(&pool->tasks_available, state);

		main_loop_continue:;
	}

	return 0;
}
