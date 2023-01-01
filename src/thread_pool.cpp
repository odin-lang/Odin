// thread_pool.cpp

struct WorkerTask;
struct ThreadPool;

gb_thread_local Thread *current_thread;

gb_internal void thread_pool_init(ThreadPool *pool, gbAllocator const &a, isize thread_count, char const *worker_name);
gb_internal void thread_pool_destroy(ThreadPool *pool);
gb_internal bool thread_pool_add_task(ThreadPool *pool, WorkerTaskProc *proc, void *data);
gb_internal void thread_pool_wait(ThreadPool *pool);

struct ThreadPool {
	gbAllocator   allocator;

	Slice<Thread> threads;
	std::atomic<bool> running;

	BlockingMutex task_lock;
	Condition     tasks_available;

	Futex tasks_left;
};

gb_internal void thread_pool_init(ThreadPool *pool, gbAllocator const &a, isize thread_count, char const *worker_name) {
	pool->allocator = a;
	slice_init(&pool->threads, a, thread_count + 1);

	// setup the main thread
	thread_init(pool, &pool->threads[0], 0);
	current_thread = &pool->threads[0];

	for_array_off(i, 1, pool->threads) {
		Thread *t = &pool->threads[i];
		thread_init_and_start(pool, t, i);
	}

	pool->running = true;
}

gb_internal void thread_pool_destroy(ThreadPool *pool) {
	pool->running = false;

	for_array_off(i, 1, pool->threads) {
		Thread *t = &pool->threads[i];
		condition_broadcast(&pool->tasks_available);
		thread_join_and_destroy(t);
	}
	for_array(i, pool->threads) {
		free(pool->threads[i].queue);
	}

	gb_free(pool->allocator, pool->threads.data);
}

void thread_pool_queue_push(Thread *thread, WorkerTask task) {
	uint64_t capture;
	uint64_t new_capture;
	do {
		capture = thread->head_and_tail.load();

		uint64_t mask = thread->capacity - 1;
		uint64_t head = (capture >> 32) & mask;
		uint64_t tail = ((uint32_t)capture) & mask;

		uint64_t new_head = (head + 1) & mask;
		if (new_head == tail) {
			GB_PANIC("Thread Queue Full!\n");
		}

		// This *must* be done in here, to avoid a potential race condition where we no longer own the slot by the time we're assigning
		thread->queue[head] = task;
		new_capture = (new_head << 32) | tail;
	} while (!thread->head_and_tail.compare_exchange_weak(capture, new_capture));

	thread->pool->tasks_left.fetch_add(1);
	condition_broadcast(&thread->pool->tasks_available);
}

bool thread_pool_queue_pop(Thread *thread, WorkerTask *task) {
	uint64_t capture;
	uint64_t new_capture;
	do {
		capture = thread->head_and_tail.load();

		uint64_t mask = thread->capacity - 1;
		uint64_t head = (capture >> 32) & mask;
		uint64_t tail = ((uint32_t)capture) & mask;

		uint64_t new_tail = (tail + 1) & mask;
		if (tail == head) {
			return false;
		}

		// Making a copy of the task before we increment the tail, avoiding the same potential race condition as above
		*task = thread->queue[tail];

		new_capture = (head << 32) | new_tail;
	} while (!thread->head_and_tail.compare_exchange_weak(capture, new_capture));

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

	while (pool->tasks_left) {

		// if we've got tasks on our queue, run them
		while (thread_pool_queue_pop(current_thread, &task)) {
			task.do_work(task.data);
			pool->tasks_left.fetch_sub(1);
		}


		// is this mem-barriered enough?
		// This *must* be executed in this order, so the futex wakes immediately
		// if rem_tasks has changed since we checked last, otherwise the program
		// will permanently sleep
		Footex rem_tasks = pool->tasks_left.load();
		if (!rem_tasks) {
			break;
		}

		futex_wait(&pool->tasks_left, rem_tasks);
	}
}

gb_internal THREAD_PROC(thread_pool_thread_proc) {
	WorkerTask task;
	current_thread = thread;
	ThreadPool *pool = current_thread->pool;

	for (;;) {
work_start:
		if (!pool->running) {
			break;
		}

		// If we've got tasks to process, work through them
		size_t finished_tasks = 0;
		while (thread_pool_queue_pop(current_thread, &task)) {
			task.do_work(task.data);
			pool->tasks_left.fetch_sub(1);

			finished_tasks += 1;
		}
		if (finished_tasks > 0 && !pool->tasks_left) {
			futex_signal(&pool->tasks_left);
		}

		// If there's still work somewhere and we don't have it, steal it
		if (pool->tasks_left) {
			isize idx = current_thread->idx;
			for_array(i, pool->threads) {
				if (!pool->tasks_left) {
					break;
				}

				idx = (idx + 1) % pool->threads.count;
				Thread *thread = &pool->threads[idx];

				WorkerTask task;
				if (!thread_pool_queue_pop(thread, &task)) {
					continue;
				}

				task.do_work(task.data);
				pool->tasks_left.fetch_sub(1);

				if (!pool->tasks_left) {
					futex_signal(&pool->tasks_left);
				}

				goto work_start;
			}
		}

		// if we've done all our work, and there's nothing to steal, go to sleep
		mutex_lock(&pool->task_lock);
		condition_wait(&pool->tasks_available, &pool->task_lock);
		mutex_unlock(&pool->task_lock);
	}

	return 0;
}
