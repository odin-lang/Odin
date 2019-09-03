// worker_queue.cpp

#define WORKER_TASK_PROC(name) isize name(void *data)
typedef WORKER_TASK_PROC(WorkerTaskProc);

struct WorkerTask {
	WorkerTaskProc *do_work;
	void *data;
};


struct ThreadPool {
	gbMutex     task_mutex;
	gbMutex     mutex;
	gbSemaphore semaphore;
	gbAtomic32  processing_work_count;
	bool        is_running;

	gbAllocator allocator;

	WorkerTask *tasks;
	isize volatile task_count;
	isize volatile task_capacity;

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
void thread_pool_kick(ThreadPool *pool);
void thread_pool_kick_and_wait(ThreadPool *pool);
GB_THREAD_PROC(worker_thread_internal);

void thread_pool_init(ThreadPool *pool, gbAllocator const &a, isize thread_count, char const *worker_prefix) {
	pool->allocator = a;
	pool->task_count = 0;
	pool->task_capacity = 1024;
	pool->tasks = gb_alloc_array(a, WorkerTask, pool->task_capacity);
	pool->threads = gb_alloc_array(a, gbThread, thread_count);
	pool->thread_count = thread_count;
	gb_mutex_init(&pool->task_mutex);
	gb_mutex_init(&pool->mutex);
	gb_semaphore_init(&pool->semaphore);
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

	for (isize i = 0; i < pool->thread_count; i++) {
		gb_semaphore_release(&pool->semaphore);
	}

	for (isize i = 0; i < pool->thread_count; i++) {
		gbThread *t = &pool->threads[i];
		gb_thread_join(t);
	}
}


void thread_pool_destroy(ThreadPool *pool) {
	thread_pool_join(pool);

	gb_semaphore_destroy(&pool->semaphore);
	gb_mutex_destroy(&pool->mutex);
	gb_mutex_destroy(&pool->task_mutex);
	gb_free(pool->allocator, pool->threads);
	pool->thread_count = 0;
	gb_free(pool->allocator, pool->tasks);
	pool->task_count = 0;
	pool->task_capacity = 0;

}


void thread_pool_add_task(ThreadPool *pool, WorkerTaskProc *proc, void *data) {
	gb_mutex_lock(&pool->task_mutex);

	if (pool->task_count == pool->task_capacity) {
		isize new_cap = 2*pool->task_capacity + 8;
		WorkerTask *new_tasks = gb_alloc_array(pool->allocator, WorkerTask, new_cap);
		gb_memmove(new_tasks, pool->tasks, pool->task_count*gb_size_of(WorkerTask));
		pool->tasks = new_tasks;
		pool->task_capacity = new_cap;
	}
	WorkerTask task = {};
	task.do_work = proc;
	task.data = data;

	pool->tasks[pool->task_count++] = task;

	gb_semaphore_post(&pool->semaphore, 1);
	gb_mutex_unlock(&pool->task_mutex);
}

void thread_pool_kick(ThreadPool *pool) {
	gb_mutex_lock(&pool->task_mutex);
	if (pool->task_count > 0) {
		isize count = gb_min(pool->task_count, pool->thread_count);
		for (isize i = 0; i < count; i++) {
			gb_semaphore_post(&pool->semaphore, 1);
		}
	}
	gb_mutex_unlock(&pool->task_mutex);
}
void thread_pool_kick_and_wait(ThreadPool *pool) {
	thread_pool_kick(pool);

	isize return_value = 0;
	while (pool->task_count > 0 || gb_atomic32_load(&pool->processing_work_count) != 0) {

		if (pool->task_count > 0 && gb_atomic32_load(&pool->processing_work_count) == 0) {
			gb_mutex_lock(&pool->task_mutex);
			for (isize i = 0; i < pool->task_count; i++) {
				gb_semaphore_post(&pool->semaphore, 1);
			}
			gb_mutex_unlock(&pool->task_mutex);
		}
		gb_yield();
	}

	thread_pool_join(pool);
}


GB_THREAD_PROC(worker_thread_internal) {
	ThreadPool *pool = cast(ThreadPool *)thread->user_data;
	thread->return_value = 0;
	while (pool->is_running) {
		gb_semaphore_wait(&pool->semaphore);

		WorkerTask task = {};
		bool got_task = false;

		if (gb_mutex_try_lock(&pool->task_mutex)) {
			if (pool->task_count > 0) {
				gb_atomic32_fetch_add(&pool->processing_work_count, +1);
				task = pool->tasks[--pool->task_count];
				got_task = true;
			}
			gb_mutex_unlock(&pool->task_mutex);
		}

		if (got_task) {
			thread->return_value = task.do_work(task.data);
			gb_atomic32_fetch_add(&pool->processing_work_count, -1);
		}
	}
	return thread->return_value;
}

