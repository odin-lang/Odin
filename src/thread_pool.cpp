// worker_queue.cpp

#define WORKER_TASK_PROC(name) isize name(void *data)
typedef WORKER_TASK_PROC(WorkerTaskProc);

struct WorkerTask {
	WorkerTaskProc *do_work;
	void *data;
	isize result;
};


struct ThreadPool {
	BlockingMutex    mutex;
	Semaphore        sem_available;
	std::atomic<i32> processing_work_count;
	bool             is_running;

	gbAllocator allocator;

	MPMCQueue<WorkerTask> tasks;

	gbThread *threads;
	isize thread_count;

	char worker_prefix[10];
	i32 worker_prefix_len;
};

void thread_pool_init(ThreadPool *pool, gbAllocator const &a, isize thread_count, char const *worker_prefix = nullptr);
void thread_pool_destroy(ThreadPool *pool);
void thread_pool_start(ThreadPool *pool);
void thread_pool_join(ThreadPool *pool);
void thread_pool_add_task(ThreadPool *pool, WorkerTaskProc *proc, void *data);
GB_THREAD_PROC(worker_thread_internal);

void thread_pool_init(ThreadPool *pool, gbAllocator const &a, isize thread_count, char const *worker_prefix) {
	pool->allocator = a;
	mpmc_init(&pool->tasks, a, 1024);
	pool->thread_count = gb_max(thread_count, 0);
	pool->threads = gb_alloc_array(a, gbThread, pool->thread_count);
	mutex_init(&pool->mutex);
	semaphore_init(&pool->sem_available);
	pool->is_running = true;

	pool->worker_prefix_len = 0;
	if (worker_prefix) {
		i32 worker_prefix_len = cast(i32)gb_strlen(worker_prefix);
		worker_prefix_len = gb_min(worker_prefix_len, 10);
		gb_memmove(pool->worker_prefix, worker_prefix, worker_prefix_len);
		pool->worker_prefix_len = worker_prefix_len;
	}

	for (isize i = 0; i < pool->thread_count; i++) {
		gbThread *t = &pool->threads[i];
		gb_thread_init(t);
		t->user_index = i;
		#if 0
		// TODO(bill): Fix this on Linux as it causes a seg-fault
		if (pool->worker_prefix_len > 0) {
			char worker_name[16] = {};
			gb_snprintf(worker_name, gb_size_of(worker_name), "%.*s%u", pool->worker_prefix_len, pool->worker_prefix, cast(u16)i);
			gb_thread_set_name(t, worker_name);
		}
		#endif
	}
}

void thread_pool_start(ThreadPool *pool) {
	for (isize i = 0; i < pool->thread_count; i++) {
		gbThread *t = &pool->threads[i];
		gb_thread_start(t, worker_thread_internal, pool);
	}
}

void thread_pool_join(ThreadPool *pool) {
	pool->is_running = false;

	semaphore_post(&pool->sem_available, cast(i32)pool->thread_count);

	gb_yield();

	for (isize i = 0; i < pool->thread_count; i++) {
		gbThread *t = &pool->threads[i];
		gb_thread_join(t);
	}
}


void thread_pool_destroy(ThreadPool *pool) {
	thread_pool_join(pool);

	semaphore_destroy(&pool->sem_available);
	mutex_destroy(&pool->mutex);
	gb_free(pool->allocator, pool->threads);
	pool->thread_count = 0;
	mpmc_destroy(&pool->tasks);
}


void thread_pool_add_task(ThreadPool *pool, WorkerTaskProc *proc, void *data) {
	mutex_lock(&pool->mutex);

	WorkerTask task = {};
	task.do_work = proc;
	task.data = data;

	mpmc_enqueue(&pool->tasks, task);
	semaphore_post(&pool->sem_available, 1);
	mutex_unlock(&pool->mutex);
}

bool thread_pool_try_and_pop_task(ThreadPool *pool, WorkerTask *task) {
	bool got_task = false;
	if (mpmc_dequeue(&pool->tasks, task)) {
		pool->processing_work_count.fetch_add(1);
		got_task = true;
	}
	return got_task;
}
void thread_pool_do_work(ThreadPool *pool, WorkerTask *task) {
	task->result = task->do_work(task->data);
	pool->processing_work_count.fetch_sub(1);
}

void thread_pool_wait_to_process(ThreadPool *pool) {
	if (pool->thread_count == 0) {
		WorkerTask task = {};
		while (thread_pool_try_and_pop_task(pool, &task)) {
			thread_pool_do_work(pool, &task);
		}
		return;
	}
	while (pool->tasks.count.load(std::memory_order_relaxed) > 0 || pool->processing_work_count.load() != 0) {
		WorkerTask task = {};
		if (thread_pool_try_and_pop_task(pool, &task)) {
			thread_pool_do_work(pool, &task);
		}

		// Safety-kick
		while (pool->tasks.count.load(std::memory_order_relaxed) > 0 && pool->processing_work_count.load() == 0) {
			mutex_lock(&pool->mutex);
			semaphore_post(&pool->sem_available, cast(i32)pool->tasks.count.load(std::memory_order_relaxed));
			mutex_unlock(&pool->mutex);
		}

		gb_yield();
	}

	thread_pool_join(pool);
}


GB_THREAD_PROC(worker_thread_internal) {
	ThreadPool *pool = cast(ThreadPool *)thread->user_data;
	while (pool->is_running) {
		semaphore_wait(&pool->sem_available);

		WorkerTask task = {};
		if (thread_pool_try_and_pop_task(pool, &task)) {
			thread_pool_do_work(pool, &task);
		}
	}
	// Cascade
	semaphore_release(&pool->sem_available);

	return 0;
}
