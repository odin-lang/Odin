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

	Array<WorkerTask> tasks;
	Array<gbThread> threads;

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
	pool->tasks = array_make<WorkerTask>(a, 0, 1024);
	pool->threads = array_make<gbThread>(a, thread_count);
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

	for_array(i, pool->threads) {
		gbThread *t = &pool->threads[i];
		gb_thread_init(t);
		t->user_index = i;
		if (pool->worker_prefix_len > 0) {
			char worker_name[16] = {};
			gb_snprintf(worker_name, gb_size_of(worker_name), "%.*s%u", pool->worker_prefix_len, pool->worker_prefix, cast(u16)i);
			gb_thread_set_name(t, worker_name);
		}
	}
}

void thread_pool_start(ThreadPool *pool) {
	for_array(i, pool->threads) {
		gbThread *t = &pool->threads[i];
		gb_thread_start(t, worker_thread_internal, pool);
	}
}

void thread_pool_join(ThreadPool *pool) {
	pool->is_running = false;

	for_array(i, pool->threads) {
		gb_semaphore_release(&pool->semaphore);
	}

	for_array(i, pool->threads) {
		gbThread *t = &pool->threads[i];
		gb_thread_join(t);
	}
}


void thread_pool_destroy(ThreadPool *pool) {
	thread_pool_join(pool);

	gb_semaphore_destroy(&pool->semaphore);
	gb_mutex_destroy(&pool->mutex);
	gb_mutex_destroy(&pool->task_mutex);
	array_free(&pool->threads);
	array_free(&pool->tasks);
}


void thread_pool_add_task(ThreadPool *pool, WorkerTaskProc *proc, void *data) {
	gb_mutex_lock(&pool->task_mutex);

	WorkerTask task = {};
	task.do_work = proc;
	task.data = data;
	array_add(&pool->tasks, task);

	gb_mutex_unlock(&pool->task_mutex);

	gb_semaphore_post(&pool->semaphore, 1);
}

void thread_pool_kick(ThreadPool *pool) {
	if (pool->tasks.count > 0) {
		isize count = gb_min(pool->tasks.count, pool->threads.count);
		for (isize i = 0; i < count; i++) {
			gb_semaphore_post(&pool->semaphore, 1);
		}
	}

}
void thread_pool_kick_and_wait(ThreadPool *pool) {
	thread_pool_kick(pool);

	isize return_value = 0;
	while (pool->tasks.count > 0 || gb_atomic32_load(&pool->processing_work_count) != 0) {
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
			if (pool->tasks.count > 0) {
				gb_atomic32_fetch_add(&pool->processing_work_count, +1);
				task = array_pop(&pool->tasks);
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

