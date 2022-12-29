#if defined(GB_SYSTEM_LINUX)
#include <signal.h>
#endif
#if defined(GB_SYSTEM_WINDOWS)
	#pragma warning(push)
	#pragma warning(disable: 4505)
#endif

struct BlockingMutex;
struct RecursiveMutex;
struct Semaphore;
struct Condition;
struct Thread;
struct ThreadPool;

#define THREAD_PROC(name) isize name(struct Thread *thread)
gb_internal THREAD_PROC(thread_pool_thread_proc);

#define WORKER_TASK_PROC(name) isize name(void *data)
typedef WORKER_TASK_PROC(WorkerTaskProc);

typedef struct WorkerTask {
	WorkerTaskProc *do_work;
	void           *data;
} WorkerTask;

struct Thread {
#if defined(GB_SYSTEM_WINDOWS)
	void *win32_handle;
#else
	pthread_t posix_handle;
#endif
	
	isize idx;

	WorkerTask *queue;
	size_t capacity;
	std::atomic<uint64_t> head_and_tail;

	isize  stack_size;
	struct ThreadPool *pool;
};


gb_internal void mutex_init    (BlockingMutex *m);
gb_internal void mutex_destroy (BlockingMutex *m);
gb_internal void mutex_lock    (BlockingMutex *m);
gb_internal bool mutex_try_lock(BlockingMutex *m);
gb_internal void mutex_unlock  (BlockingMutex *m);
gb_internal void mutex_init    (RecursiveMutex *m);
gb_internal void mutex_destroy (RecursiveMutex *m);
gb_internal void mutex_lock    (RecursiveMutex *m);
gb_internal bool mutex_try_lock(RecursiveMutex *m);
gb_internal void mutex_unlock  (RecursiveMutex *m);

gb_internal void semaphore_init   (Semaphore *s);
gb_internal void semaphore_destroy(Semaphore *s);
gb_internal void semaphore_post   (Semaphore *s, i32 count);
gb_internal void semaphore_wait   (Semaphore *s);
gb_internal void semaphore_release(Semaphore *s) { semaphore_post(s, 1); }


gb_internal void condition_init(Condition *c);
gb_internal void condition_destroy(Condition *c);
gb_internal void condition_broadcast(Condition *c);
gb_internal void condition_signal(Condition *c);
gb_internal void condition_wait(Condition *c, BlockingMutex *m);
gb_internal void condition_wait_with_timeout(Condition *c, BlockingMutex *m, u32 timeout_in_ms);

gb_internal u32  thread_current_id(void);

gb_internal void thread_init                     (ThreadPool *pool, Thread *t, isize idx);
gb_internal void thread_init_and_start           (ThreadPool *pool, Thread *t, isize idx);
gb_internal void thread_join_and_destroy(Thread *t);
gb_internal void thread_set_name        (Thread *t, char const *name);

gb_internal void yield_thread(void);
gb_internal void yield_process(void);


struct MutexGuard {
	MutexGuard() = delete;
	MutexGuard(MutexGuard const &) = delete;

	MutexGuard(BlockingMutex *bm) : bm{bm} {
		mutex_lock(this->bm);
	}
	MutexGuard(RecursiveMutex *rm) : rm{rm} {
		mutex_lock(this->rm);
	}
	MutexGuard(BlockingMutex &bm) : bm{&bm} {
		mutex_lock(this->bm);
	}
	MutexGuard(RecursiveMutex &rm) : rm{&rm} {
		mutex_lock(this->rm);
	}
	~MutexGuard() {
		if (this->bm) {
			mutex_unlock(this->bm);
		} else if (this->rm) {
			mutex_unlock(this->rm);
		}
	}

	operator bool() const { return true; }

	BlockingMutex *bm;
	RecursiveMutex *rm;
};

#define MUTEX_GUARD_BLOCK(m) if (MutexGuard GB_DEFER_3(_mutex_guard_){m})
#define MUTEX_GUARD(m) MutexGuard GB_DEFER_3(_mutex_guard_){m}


#if defined(GB_SYSTEM_WINDOWS)
	struct BlockingMutex {
		SRWLOCK srwlock;
	};
	gb_internal void mutex_init(BlockingMutex *m) {
	}
	gb_internal void mutex_destroy(BlockingMutex *m) {
	}
	gb_internal void mutex_lock(BlockingMutex *m) {
		AcquireSRWLockExclusive(&m->srwlock);
	}
	gb_internal bool mutex_try_lock(BlockingMutex *m) {
		return !!TryAcquireSRWLockExclusive(&m->srwlock);
	}
	gb_internal void mutex_unlock(BlockingMutex *m) {
		ReleaseSRWLockExclusive(&m->srwlock);
	}

	struct RecursiveMutex {
		CRITICAL_SECTION win32_critical_section;
	};
	gb_internal void mutex_init(RecursiveMutex *m) {
		InitializeCriticalSection(&m->win32_critical_section);
	}
	gb_internal void mutex_destroy(RecursiveMutex *m) {
		DeleteCriticalSection(&m->win32_critical_section);
	}
	gb_internal void mutex_lock(RecursiveMutex *m) {
		EnterCriticalSection(&m->win32_critical_section);
	}
	gb_internal bool mutex_try_lock(RecursiveMutex *m) {
		return TryEnterCriticalSection(&m->win32_critical_section) != 0;
	}
	gb_internal void mutex_unlock(RecursiveMutex *m) {
		LeaveCriticalSection(&m->win32_critical_section);
	}

	struct Semaphore {
		void *win32_handle;
	};

	gb_internal void semaphore_init(Semaphore *s) {
		s->win32_handle = CreateSemaphoreA(NULL, 0, I32_MAX, NULL);
	}
	gb_internal void semaphore_destroy(Semaphore *s) {
		CloseHandle(s->win32_handle);
	}
	gb_internal void semaphore_post(Semaphore *s, i32 count) {
		ReleaseSemaphore(s->win32_handle, count, NULL);
	}
	gb_internal void semaphore_wait(Semaphore *s) {
		WaitForSingleObjectEx(s->win32_handle, INFINITE, FALSE);
	}
	
	struct Condition {
		CONDITION_VARIABLE cond;
	};
	
	gb_internal void condition_init(Condition *c) {
	}
	gb_internal void condition_destroy(Condition *c) {
	}
	gb_internal void condition_broadcast(Condition *c) {
		WakeAllConditionVariable(&c->cond);
	}
	gb_internal void condition_signal(Condition *c) {
		WakeConditionVariable(&c->cond);
	}
	gb_internal void condition_wait(Condition *c, BlockingMutex *m) {
		SleepConditionVariableSRW(&c->cond, &m->srwlock, INFINITE, 0);
	}
	gb_internal void condition_wait_with_timeout(Condition *c, BlockingMutex *m, u32 timeout_in_ms) {
		SleepConditionVariableSRW(&c->cond, &m->srwlock, timeout_in_ms, 0);
	}

#else
	struct BlockingMutex {
		pthread_mutex_t pthread_mutex;
	};
	gb_internal void mutex_init(BlockingMutex *m) {
		pthread_mutex_init(&m->pthread_mutex, nullptr);
	}
	gb_internal void mutex_destroy(BlockingMutex *m) {
		pthread_mutex_destroy(&m->pthread_mutex);
	}
	gb_internal void mutex_lock(BlockingMutex *m) {
		pthread_mutex_lock(&m->pthread_mutex);
	}
	gb_internal bool mutex_try_lock(BlockingMutex *m) {
		return pthread_mutex_trylock(&m->pthread_mutex) == 0;
	}
	gb_internal void mutex_unlock(BlockingMutex *m) {
		pthread_mutex_unlock(&m->pthread_mutex);
	}

	struct RecursiveMutex {
		pthread_mutex_t pthread_mutex;
		pthread_mutexattr_t pthread_mutexattr;
	};
	gb_internal void mutex_init(RecursiveMutex *m) {
		pthread_mutexattr_init(&m->pthread_mutexattr);
		pthread_mutexattr_settype(&m->pthread_mutexattr, PTHREAD_MUTEX_RECURSIVE);
		pthread_mutex_init(&m->pthread_mutex, &m->pthread_mutexattr);
	}
	gb_internal void mutex_destroy(RecursiveMutex *m) {
		pthread_mutex_destroy(&m->pthread_mutex);
	}
	gb_internal void mutex_lock(RecursiveMutex *m) {
		pthread_mutex_lock(&m->pthread_mutex);
	}
	gb_internal bool mutex_try_lock(RecursiveMutex *m) {
		return pthread_mutex_trylock(&m->pthread_mutex) == 0;
	}
	gb_internal void mutex_unlock(RecursiveMutex *m) {
		pthread_mutex_unlock(&m->pthread_mutex);
	}

	#if defined(GB_SYSTEM_OSX)
		struct Semaphore {
			semaphore_t osx_handle;
		};

		gb_internal void semaphore_init   (Semaphore *s)            { semaphore_create(mach_task_self(), &s->osx_handle, SYNC_POLICY_FIFO, 0); }
		gb_internal void semaphore_destroy(Semaphore *s)            { semaphore_destroy(mach_task_self(), s->osx_handle); }
		gb_internal void semaphore_post   (Semaphore *s, i32 count) { while (count --> 0) semaphore_signal(s->osx_handle); }
		gb_internal void semaphore_wait   (Semaphore *s)            { semaphore_wait(s->osx_handle); }
	#elif defined(GB_SYSTEM_UNIX)
		struct Semaphore {
			sem_t unix_handle;
		};

		gb_internal void semaphore_init   (Semaphore *s)            { sem_init(&s->unix_handle, 0, 0); }
		gb_internal void semaphore_destroy(Semaphore *s)            { sem_destroy(&s->unix_handle); }
		gb_internal void semaphore_post   (Semaphore *s, i32 count) { while (count --> 0) sem_post(&s->unix_handle); }
		void semaphore_wait   (Semaphore *s)            { int i; do { i = sem_wait(&s->unix_handle); } while (i == -1 && errno == EINTR); }
	#else
	#error Implement Semaphore for this platform
	#endif
		
		
	struct Condition {
		pthread_cond_t pthread_cond;
	};
	
	gb_internal void condition_init(Condition *c) {
		pthread_cond_init(&c->pthread_cond, NULL);
	}
	gb_internal void condition_destroy(Condition *c) {
		pthread_cond_destroy(&c->pthread_cond);
	}
	gb_internal void condition_broadcast(Condition *c) {
		pthread_cond_broadcast(&c->pthread_cond);
	}
	gb_internal void condition_signal(Condition *c) {
		pthread_cond_signal(&c->pthread_cond);
	}
	gb_internal void condition_wait(Condition *c, BlockingMutex *m) {
		pthread_cond_wait(&c->pthread_cond, &m->pthread_mutex);
	}
	gb_internal void condition_wait_with_timeout(Condition *c, BlockingMutex *m, u32 timeout_in_ms) {
		struct timespec abstime = {};
		abstime.tv_sec = timeout_in_ms/1000;
		abstime.tv_nsec = cast(long)(timeout_in_ms%1000)*1e6;
		pthread_cond_timedwait(&c->pthread_cond, &m->pthread_mutex, &abstime);
		
	}
#endif


gb_internal u32 thread_current_id(void) {
	u32 thread_id;
#if defined(GB_SYSTEM_WINDOWS)
	#if defined(GB_ARCH_32_BIT) && defined(GB_CPU_X86)
		thread_id = (cast(u32 *)__readfsdword(24))[9];
	#elif defined(GB_ARCH_64_BIT) && defined(GB_CPU_X86)
		thread_id = (cast(u32 *)__readgsqword(48))[18];
	#else
		thread_id = GetCurrentThreadId();
	#endif

#elif defined(GB_SYSTEM_OSX) && defined(GB_ARCH_64_BIT)
	thread_id = pthread_mach_thread_np(pthread_self());
#elif defined(GB_ARCH_32_BIT) && defined(GB_CPU_X86)
	__asm__("mov %%gs:0x08,%0" : "=r"(thread_id));
#elif defined(GB_ARCH_64_BIT) && defined(GB_CPU_X86)
	__asm__("mov %%fs:0x10,%0" : "=r"(thread_id));
#elif defined(GB_SYSTEM_LINUX)
	thread_id = gettid();
#else
	#error Unsupported architecture for thread_current_id()
#endif

	return thread_id;
}


gb_internal gb_inline void yield_thread(void) {
#if defined(GB_SYSTEM_WINDOWS)
	_mm_pause();
#elif defined(GB_SYSTEM_OSX)
	#if defined(GB_CPU_X86)
	__asm__ volatile ("" : : : "memory");
	#elif defined(GB_CPU_ARM)
	__asm__ volatile ("yield" : : : "memory");
	#endif
#elif defined(GB_CPU_X86)
	_mm_pause();
#elif defined(GB_CPU_ARM)
	__asm__ volatile ("yield" : : : "memory");
#else
#error Unknown architecture
#endif
}

gb_internal gb_inline void yield(void) {
#if defined(GB_SYSTEM_WINDOWS)
	YieldProcessor();
#else
	sched_yield();
#endif
}

#if defined(GB_SYSTEM_WINDOWS)
gb_internal DWORD __stdcall internal_thread_proc(void *arg) {
	Thread *t = cast(Thread *)arg;
	thread_pool_thread_proc(t);
	return 0;
}
#else
gb_internal void *internal_thread_proc(void *arg) {
#if (GB_SYSTEM_LINUX)
	// NOTE: Don't permit any signal delivery to threads on Linux.
	sigset_t mask = {};
	sigfillset(&mask);
	GB_ASSERT_MSG(pthread_sigmask(SIG_BLOCK, &mask, nullptr) == 0, "failed to block signals");
#endif
	
	Thread *t = cast(Thread *)arg;
	thread_pool_thread_proc(t);
	return NULL;
}
#endif

gb_internal void thread_init(ThreadPool *pool, Thread *t, isize idx) {
	gb_zero_item(t);
#if defined(GB_SYSTEM_WINDOWS)
	t->win32_handle = INVALID_HANDLE_VALUE;
#else
	t->posix_handle = 0;
#endif

	t->capacity = 1 << 14; // must be a power of 2
	t->queue = (WorkerTask *)calloc(sizeof(WorkerTask), t->capacity);
	t->head_and_tail = 0;
	t->pool = pool;
	t->idx = idx;
}

gb_internal void thread_init_and_start(ThreadPool *pool, Thread *t, isize idx) {
	thread_init(pool, t, idx);
	isize stack_size = 0;

#if defined(GB_SYSTEM_WINDOWS)
	t->win32_handle = CreateThread(NULL, stack_size, internal_thread_proc, t, 0, NULL);
	GB_ASSERT_MSG(t->win32_handle != NULL, "CreateThread: GetLastError");
#else
	{
		pthread_attr_t attr;
		pthread_attr_init(&attr);
		defer (pthread_attr_destroy(&attr));
		pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE);
		if (stack_size != 0) {
			pthread_attr_setstacksize(&attr, stack_size);
		}
		pthread_create(&t->posix_handle, &attr, internal_thread_proc, t);
	}
#endif
}

gb_internal void thread_join_and_destroy(Thread *t) {
#if defined(GB_SYSTEM_WINDOWS)
	WaitForSingleObject(t->win32_handle, INFINITE);
	CloseHandle(t->win32_handle);
	t->win32_handle = INVALID_HANDLE_VALUE;
#else
	pthread_join(t->posix_handle, NULL);
	t->posix_handle = 0;
#endif
}

gb_internal void thread_set_name(Thread *t, char const *name) {
#if defined(GB_COMPILER_MSVC)
	#pragma pack(push, 8)
		typedef struct {
			DWORD       type;
			char const *name;
			DWORD       id;
			DWORD       flags;
		} gbprivThreadName;
	#pragma pack(pop)
		gbprivThreadName tn;
		tn.type  = 0x1000;
		tn.name  = name;
		tn.id    = GetThreadId(cast(HANDLE)t->win32_handle);
		tn.flags = 0;

		__try {
			RaiseException(0x406d1388, 0, gb_size_of(tn)/4, cast(ULONG_PTR *)&tn);
		} __except(1 /*EXCEPTION_EXECUTE_HANDLER*/) {
		}

#elif defined(GB_SYSTEM_WINDOWS) && !defined(GB_COMPILER_MSVC)
	// IMPORTANT TODO(bill): Set thread name for GCC/Clang on windows
	return;
#elif defined(GB_SYSTEM_OSX)
	// TODO(bill): Test if this works
	pthread_setname_np(name);
#elif defined(GB_SYSTEM_FREEBSD) || defined(GB_SYSTEM_OPENBSD)
	pthread_set_name_np(t->posix_handle, name);
#else
	// TODO(bill): Test if this works
	pthread_setname_np(t->posix_handle, name);
#endif
}

#if defined(GB_SYSTEM_LINUX)
#include <linux/futex.h>
#include <sys/syscall.h>

typedef std::atomic<int32_t> Futex;
typedef volatile int32_t Footex;

gb_internal void tpool_wake_addr(Futex *addr) {
	for (;;) {
		int ret = syscall(SYS_futex, addr, FUTEX_WAKE, 1, NULL, NULL, 0);
		if (ret == -1) {
			perror("Futex wake");
			GB_PANIC("Failed in futex wake!\n");
		} else if (ret > 0) {
			return;
		}
	}
}

gb_internal void tpool_wait_on_addr(Futex *addr, Footex val) {
	for (;;) {
		int ret = syscall(SYS_futex, addr, FUTEX_WAIT, val, NULL, NULL, 0);
		if (ret == -1) {
			if (errno != EAGAIN) {
				perror("Futex wait");
				GB_PANIC("Failed in futex wait!\n");
			} else {
				return;
			}
		} else if (ret == 0) {
			if (*addr != val) {
				return;
			}
		}
	}
}

#elif defined(GB_SYSTEM_FREEBSD)

#include <sys/types.h>
#include <sys/umtx.h>

typedef std::atomic<int32_t> Futex;
typedef volatile int32_t Footex;

gb_internal void tpool_wake_addr(Futex *addr) {
	_umtx_op(addr, UMTX_OP_WAKE, 1, 0, 0);
}

gb_internal void tpool_wait_on_addr(Futex *addr, Footex val) {
	for (;;) {
		int ret = _umtx_op(addr, UMTX_OP_WAIT_UINT, val, 0, NULL);
		if (ret == 0) {
			if (errno == ETIMEDOUT || errno == EINTR) {
				continue;
			}

			perror("Futex wait");
			GB_PANIC("Failed in futex wait!\n");
		} else if (ret == 0) {
			if (*addr != val) {
				return;
			}
		}
	}
}

#elif defined(GB_SYSTEM_OSX)

typedef std::atomic<int64_t> Futex;
typedef volatile int64_t Footex;

#define UL_COMPARE_AND_WAIT	0x00000001
#define ULF_NO_ERRNO        0x01000000

extern "C" int __ulock_wait(uint32_t operation, void *addr, uint64_t value, uint32_t timeout); /* timeout is specified in microseconds */
extern "C" int __ulock_wake(uint32_t operation, void *addr, uint64_t wake_value);

gb_internal void tpool_wake_addr(Futex *addr) {
	for (;;) {
		int ret = __ulock_wake(UL_COMPARE_AND_WAIT | ULF_NO_ERRNO, addr, 0);
		if (ret >= 0) {
			return;
		}
		if (ret == EINTR || ret == EFAULT) {
			continue;
		}
		if (ret == ENOENT) {
			return;
		}
		GB_PANIC("Failed in futex wake!\n");
	}
}

gb_internal void tpool_wait_on_addr(Futex *addr, Footex val) {
	for (;;) {
		int ret = __ulock_wait(UL_COMPARE_AND_WAIT | ULF_NO_ERRNO, addr, val, 0);
		if (ret >= 0) {
			if (*addr != val) {
				return;
			}
			continue;
		}
		if (ret == EINTR || ret == EFAULT) {
			continue;
		}
		if (ret == ENOENT) {
			return;
		}

		GB_PANIC("Failed in futex wait!\n");
	}
}
#elif defined(GB_SYSTEM_WINDOWS)
typedef std::atomic<int64_t> Futex;
typedef volatile int64_t Footex;

gb_internal void tpool_wake_addr(Futex *addr) {
	WakeByAddressSingle((void *)addr);
}

gb_internal void tpool_wait_on_addr(Futex *addr, Footex val) {
	for (;;) {
		WaitOnAddress(addr, (void *)&val, sizeof(val), INFINITE);
		if (*addr != val) break;
	}
}
#endif

#if defined(GB_SYSTEM_WINDOWS)
	#pragma warning(pop)
#endif
