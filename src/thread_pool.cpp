// thread_pool.cpp

struct WorkerTask;
struct ThreadPool;

gb_thread_local Thread *current_thread;

gb_internal void thread_pool_init(ThreadPool *pool, isize worker_count, char const *worker_name);
gb_internal void thread_pool_destroy(ThreadPool *pool);
gb_internal bool thread_pool_add_task(ThreadPool *pool, WorkerTaskProc *proc, void *data);
gb_internal void thread_pool_wait(ThreadPool *pool);

struct ThreadPool {
	gbAllocator threads_allocator;
	Slice<Thread> threads;
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
		pool->tasks_available.fetch_add(1, std::memory_order_relaxed);
		futex_broadcast(&pool->tasks_available);
		thread_join_and_destroy(t);
	}

	gb_free(pool->threads_allocator, pool->threads.data);
}

void thread_pool_queue_push(Thread *thread, WorkerTask task) {
	u64 capture;
	u64 new_capture;
	do {
		capture = thread->head_and_tail.load();

		u64 mask = thread->capacity - 1;
		u64 head = (capture >> 32) & mask;
		u64 tail = ((u32)capture) & mask;

		u64 new_head = (head + 1) & mask;
		GB_ASSERT_MSG(new_head != tail, "Thread Queue Full!");

		// This *must* be done in here, to avoid a potential race condition where we no longer own the slot by the time we're assigning
		thread->queue[head] = task;
		new_capture = (new_head << 32) | tail;
	} while (!thread->head_and_tail.compare_exchange_weak(capture, new_capture));

	thread->pool->tasks_left.fetch_add(1, std::memory_order_release);
	thread->pool->tasks_available.fetch_add(1, std::memory_order_relaxed);
	futex_broadcast(&thread->pool->tasks_available);
}

bool thread_pool_queue_pop(Thread *thread, WorkerTask *task) {
	u64 capture;
	u64 new_capture;
	do {
		capture = thread->head_and_tail.load(std::memory_order_acquire);

		u64 mask = thread->capacity - 1;
		u64 head = (capture >> 32) & mask;
		u64 tail = ((u32)capture) & mask;

		u64 new_tail = (tail + 1) & mask;
		if (tail == head) {
			return false;
		}

		// Making a copy of the task before we increment the tail, avoiding the same potential race condition as above
		*task = thread->queue[tail];

		new_capture = (head << 32) | new_tail;
	} while (!thread->head_and_tail.compare_exchange_weak(capture, new_capture, std::memory_order_release));

	return true;
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
		while (thread_pool_queue_pop(current_thread, &task)) {
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

		while (thread_pool_queue_pop(current_thread, &task)) {
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
				if (thread_pool_queue_pop(thread, &task)) {
					task.do_work(task.data);
					pool->tasks_left.fetch_sub(1, std::memory_order_release);

					if (pool->tasks_left.load(std::memory_order_acquire) == 0) {
						futex_signal(&pool->tasks_left);
					}

					goto main_loop_continue;
				}
			}
		}

		// if we've done all our work, and there's nothing to steal, go to sleep
		state = pool->tasks_available.load(std::memory_order_acquire);
		futex_wait(&pool->tasks_available, state);

		main_loop_continue:;
	}

	return 0;
}
