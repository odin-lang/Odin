// thread_pool.cpp

#define WORKER_TASK_PROC(name) isize name(void *data)
typedef WORKER_TASK_PROC(WorkerTaskProc);

struct WorkerTask {
	WorkerTask *next_task;
	WorkerTaskProc *do_work;
	void *data;
};

struct ThreadPool {
	std::atomic<isize> outstanding_task_count;
	WorkerTask *next_task;
	BlockingMutex task_list_mutex;
};

void thread_pool_init(ThreadPool *pool, gbAllocator const &a, isize thread_count, char const *worker_prefix = nullptr);
void thread_pool_destroy(ThreadPool *pool);
void thread_pool_wait(ThreadPool *pool);
void thread_pool_add_task(ThreadPool *pool, WorkerTaskProc *proc, void *data);
void worker_thread_internal();

void thread_pool_thread_entry(ThreadPool *pool) {
	while (pool->outstanding_task_count) {
		mutex_lock(&pool->task_list_mutex);

		if (pool->next_task) {
			WorkerTask *task = pool->next_task;
			pool->next_task = task->next_task;
			mutex_unlock(&pool->task_list_mutex);
			task->do_work(task->data);
			pool->outstanding_task_count.fetch_sub(1);
			gb_free(heap_allocator(), task);
		} else {
			mutex_unlock(&pool->task_list_mutex);
			yield();
		}
	}
}

#if defined(GB_SYSTEM_WINDOWS)
	DWORD __stdcall thread_pool_thread_entry_platform(void *arg) {
		thread_pool_thread_entry((ThreadPool *) arg);
		return 0;
	}

	void thread_pool_start_thread(ThreadPool *pool) {
		CloseHandle(CreateThread(NULL, 0, thread_pool_thread_entry_platform, pool, 0, NULL));
	}
#else
	void *thread_pool_thread_entry_platform(void *arg) {
		thread_pool_thread_entry((ThreadPool *) arg);
		return NULL;
	}

	void thread_pool_start_thread(ThreadPool *pool) {
		pthread_t handle;
		pthread_create(&handle, NULL, thread_pool_thread_entry_platform, pool);
		pthread_detach(handle);
	}
#endif

void thread_pool_init(ThreadPool *pool, gbAllocator const &a, isize thread_count, char const *worker_prefix) {
	memset(pool, 0, sizeof(ThreadPool));
	mutex_init(&pool->task_list_mutex);
	pool->outstanding_task_count.store(1);

	for (int i = 0; i < thread_count; i++) {
		thread_pool_start_thread(pool);
	}
}

void thread_pool_destroy(ThreadPool *pool) {
	mutex_destroy(&pool->task_list_mutex);
}

void thread_pool_wait(ThreadPool *pool) {
	pool->outstanding_task_count.fetch_sub(1);

	while (pool->outstanding_task_count.load() != 0) {
		yield();
	}
}

void thread_pool_add_task(ThreadPool *pool, WorkerTaskProc *proc, void *data) {
	WorkerTask *task = gb_alloc_item(heap_allocator(), WorkerTask);
	task->do_work = proc;
	task->data = data;
	mutex_lock(&pool->task_list_mutex);
	task->next_task = pool->next_task;
	pool->next_task = task;
	pool->outstanding_task_count.fetch_add(1);
	mutex_unlock(&pool->task_list_mutex);
}
