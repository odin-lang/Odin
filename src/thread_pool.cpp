// thread_pool.cpp

#define WORKER_TASK_PROC(name) isize name(void *data)
typedef WORKER_TASK_PROC(WorkerTaskProc);

struct WorkerTask {
	WorkerTask *    next;
	WorkerTaskProc *do_work;
	void *          data;
};

struct ThreadPool {
	gbAllocator   allocator;
	BlockingMutex mutex;
	Condition     task_cond;
	
	Slice<Thread> threads;
	
	WorkerTask *task_queue;
	
	std::atomic<isize> ready;
	std::atomic<bool>  stop;
	
};

THREAD_PROC(thread_pool_thread_proc);

void thread_pool_init(ThreadPool *pool, gbAllocator const &a, isize thread_count, char const *worker_name) {
	pool->allocator = a;
	pool->stop = false;
	mutex_init(&pool->mutex);
	condition_init(&pool->task_cond);
	
	slice_init(&pool->threads, a, thread_count);
	for_array(i, pool->threads) {
		Thread *t = &pool->threads[i];
		thread_init(t);
	}
	
	for_array(i, pool->threads) {
		Thread *t = &pool->threads[i];
		thread_start(t, thread_pool_thread_proc, pool);
	}
}

void thread_pool_destroy(ThreadPool *pool) {
	mutex_lock(&pool->mutex);
	pool->stop = true;
	condition_broadcast(&pool->task_cond);
	mutex_unlock(&pool->mutex);

	for_array(i, pool->threads) {
		Thread *t = &pool->threads[i];
		thread_join(t);
	}
	
	for_array(i, pool->threads) {
		Thread *t = &pool->threads[i];
		thread_destroy(t);
	}
	
	gb_free(pool->allocator, pool->threads.data);
	mutex_destroy(&pool->mutex);
	condition_destroy(&pool->task_cond);
}

bool thread_pool_queue_empty(ThreadPool *pool) {
	return pool->task_queue == nullptr;
}

WorkerTask *thread_pool_queue_pop(ThreadPool *pool) {
	GB_ASSERT(pool->task_queue != nullptr);
	WorkerTask *task = pool->task_queue;
	pool->task_queue = task->next;
	return task;
}
void thread_pool_queue_push(ThreadPool *pool, WorkerTask *task) {
	GB_ASSERT(task != nullptr);
	task->next = pool->task_queue;
	pool->task_queue = task;
}

bool thread_pool_add_task(ThreadPool *pool, WorkerTaskProc *proc, void *data) {
	GB_ASSERT(proc != nullptr);
	mutex_lock(&pool->mutex);
	WorkerTask *task = gb_alloc_item(permanent_allocator(), WorkerTask);
	if (task == nullptr) {
		mutex_unlock(&pool->mutex);
		GB_PANIC("Out of memory");
		return false;
	}
	task->do_work = proc;
	task->data = data;
		
	thread_pool_queue_push(pool, task);
	GB_ASSERT(pool->ready >= 0);
	pool->ready++;
	condition_broadcast(&pool->task_cond);
	mutex_unlock(&pool->mutex);
	return true;
}	


void thread_pool_do_task(WorkerTask *task) {
	task->do_work(task->data);
}

void thread_pool_wait(ThreadPool *pool) {
	if (pool->threads.count == 0) {
		while (!thread_pool_queue_empty(pool)) {
			thread_pool_do_task(thread_pool_queue_pop(pool));
			--pool->ready;
		}
		GB_ASSERT(pool->ready == 0);
		return;
	}
	for (;;) {
		mutex_lock(&pool->mutex);

		while (!pool->stop && pool->ready > 0 && thread_pool_queue_empty(pool)) {
			condition_wait(&pool->task_cond, &pool->mutex);
		}
		if ((pool->stop || pool->ready == 0) && thread_pool_queue_empty(pool)) {
			mutex_unlock(&pool->mutex);
			return;
		}

		WorkerTask *task = thread_pool_queue_pop(pool);
		mutex_unlock(&pool->mutex);
	
		thread_pool_do_task(task);
		if (--pool->ready == 0) {
			mutex_lock(&pool->mutex);
			condition_broadcast(&pool->task_cond);
			mutex_unlock(&pool->mutex);
		}
	}
}


THREAD_PROC(thread_pool_thread_proc) {
	ThreadPool *pool = cast(ThreadPool *)thread->user_data;
	
	for (;;) {
		mutex_lock(&pool->mutex);

		while (!pool->stop && thread_pool_queue_empty(pool)) {
			condition_wait(&pool->task_cond, &pool->mutex);
		}
		if (pool->stop && thread_pool_queue_empty(pool)) {
			mutex_unlock(&pool->mutex);
			return 0;
		}

		WorkerTask *task = thread_pool_queue_pop(pool);
		mutex_unlock(&pool->mutex);
	
		thread_pool_do_task(task);
		if (--pool->ready == 0) {
			mutex_lock(&pool->mutex);
			condition_broadcast(&pool->task_cond);
			mutex_unlock(&pool->mutex);
		}
	}
}