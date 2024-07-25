#if defined(GB_SYSTEM_LINUX)
#include <signal.h>
#if __has_include(<valgrind/helgrind.h>)
#include <valgrind/helgrind.h>
#define HAS_VALGRIND
#endif
#endif
#if defined(GB_SYSTEM_WINDOWS)
	#pragma warning(push)
	#pragma warning(disable: 4505)
#endif

#if defined(HAS_VALGRIND)
#define ANNOTATE_LOCK_PRE(m, t) VALGRIND_HG_MUTEX_LOCK_PRE(m, t)
#define ANNOTATE_LOCK_POST(m) VALGRIND_HG_MUTEX_LOCK_POST(m)
#define ANNOTATE_UNLOCK_PRE(m) VALGRIND_HG_MUTEX_UNLOCK_PRE(m)
#define ANNOTATE_UNLOCK_POST(m) VALGRIND_HG_MUTEX_UNLOCK_POST(m)
#define ANNOTATE_SEM_WAIT_POST(s) VALGRIND_HG_SEM_WAIT_POST(s)
#define ANNOTATE_SEM_POST_PRE(s) VALGRIND_HG_SEM_POST_PRE(s)
#else
#define ANNOTATE_LOCK_PRE(m, t)
#define ANNOTATE_LOCK_POST(m)
#define ANNOTATE_UNLOCK_PRE(m)
#define ANNOTATE_UNLOCK_POST(m)
#define ANNOTATE_SEM_WAIT_POST(s)
#define ANNOTATE_SEM_POST_PRE(s)
#endif

struct BlockingMutex;
struct RecursiveMutex;
struct RwMutex;
struct Semaphore;
struct Condition;
struct Thread;
struct ThreadPool;
struct Parker;

#define THREAD_PROC(name) isize name(struct Thread *thread)
gb_internal THREAD_PROC(thread_pool_thread_proc);

#define WORKER_TASK_PROC(name) isize name(void *data)
typedef WORKER_TASK_PROC(WorkerTaskProc);

typedef struct WorkerTask {
	WorkerTaskProc *do_work;
	void           *data;
} WorkerTask;

typedef struct TaskRingBuffer {
	std::atomic<isize> size;
	std::atomic<WorkerTask *> buffer;
} TaskRingBuffer;

typedef struct TaskQueue {
	std::atomic<isize> top;
	std::atomic<isize> bottom;

	std::atomic<TaskRingBuffer *> ring;
} TaskQueue;

struct Thread {
#if defined(GB_SYSTEM_WINDOWS)
	void *win32_handle;
#else
	pthread_t posix_handle;
#endif

	isize idx;
	isize stack_size;

	struct TaskQueue   queue;
	struct ThreadPool *pool;

	struct Arena *permanent_arena;
	struct Arena *temporary_arena;
};

typedef std::atomic<i32> Futex;
typedef volatile i32     Footex;

gb_internal void futex_wait(Futex *addr, Footex val);
gb_internal void futex_signal(Futex *addr);
gb_internal void futex_broadcast(Futex *addr);

gb_internal void mutex_lock    (BlockingMutex *m);
gb_internal bool mutex_try_lock(BlockingMutex *m);
gb_internal void mutex_unlock  (BlockingMutex *m);

gb_internal void mutex_lock    (RecursiveMutex *m);
gb_internal bool mutex_try_lock(RecursiveMutex *m);
gb_internal void mutex_unlock  (RecursiveMutex *m);

gb_internal void rw_mutex_lock           (RwMutex *m);
gb_internal bool rw_mutex_try_lock       (RwMutex *m);
gb_internal void rw_mutex_unlock         (RwMutex *m);
gb_internal void rw_mutex_shared_lock    (RwMutex *m);
gb_internal bool rw_mutex_try_shared_lock(RwMutex *m);
gb_internal void rw_mutex_shared_unlock  (RwMutex *m);

gb_internal void semaphore_post(Semaphore *s, i32 count);
gb_internal void semaphore_wait(Semaphore *s);


gb_internal void condition_broadcast(Condition *c);
gb_internal void condition_signal(Condition *c);
gb_internal void condition_wait(Condition *c, BlockingMutex *m);

gb_internal void park(Parker *p);
gb_internal void unpark_one(Parker *p);
gb_internal void unpark_all(Parker *p);

gb_internal u32  thread_current_id(void);

gb_internal void thread_init                     (ThreadPool *pool, Thread *t, isize idx);
gb_internal void thread_init_and_start           (ThreadPool *pool, Thread *t, isize idx);
gb_internal void thread_join_and_destroy(Thread *t);
gb_internal void thread_set_name        (Thread *t, char const *name);

gb_internal void yield_thread(void);
gb_internal void yield_process(void);

struct Wait_Signal {
	Futex futex;
};

gb_internal void wait_signal_until_available(Wait_Signal *ws) {
	if (ws->futex.load() == 0) {
		futex_wait(&ws->futex, 0);
	}
}

gb_internal void wait_signal_set(Wait_Signal *ws) {
	ws->futex.store(1);
	futex_broadcast(&ws->futex);
}

struct MutexGuard {
	MutexGuard()                   = delete;
	MutexGuard(MutexGuard const &) = delete;
	MutexGuard(MutexGuard &&)      = delete;

	explicit MutexGuard(BlockingMutex *bm) noexcept : bm{bm} {
		mutex_lock(this->bm);
	}
	explicit MutexGuard(RecursiveMutex *rm) noexcept : rm{rm} {
		mutex_lock(this->rm);
	}
	explicit MutexGuard(RwMutex *rwm) noexcept : rwm{rwm} {
		rw_mutex_lock(this->rwm);
	}
	explicit MutexGuard(BlockingMutex &bm) noexcept : bm{&bm} {
		mutex_lock(this->bm);
	}
	explicit MutexGuard(RecursiveMutex &rm) noexcept : rm{&rm} {
		mutex_lock(this->rm);
	}
	explicit MutexGuard(RwMutex &rwm) noexcept : rwm{&rwm} {
		rw_mutex_lock(this->rwm);
	}
	~MutexGuard() noexcept {
		if (this->bm) {
			mutex_unlock(this->bm);
		} else if (this->rm) {
			mutex_unlock(this->rm);
		} else if (this->rwm) {
			rw_mutex_unlock(this->rwm);
		}
	}

	operator bool() const noexcept { return true; }

	BlockingMutex *bm;
	RecursiveMutex *rm;
	RwMutex *rwm;
};

#define MUTEX_GUARD_BLOCK(m) if (MutexGuard GB_DEFER_3(_mutex_guard_){m})
#define MUTEX_GUARD(m) mutex_lock(m); defer (mutex_unlock(m))
#define RW_MUTEX_GUARD(m) rw_mutex_lock(m); defer (rw_mutex_unlock(m))


struct RecursiveMutex {
	Futex owner;
	i32   recursion;
};

gb_internal void mutex_lock(RecursiveMutex *m) {
	Futex tid;
	tid.store(cast(i32)thread_current_id());
	for (;;) {
		i32 prev_owner = 0;
		m->owner.compare_exchange_strong(prev_owner, tid, std::memory_order_acquire, std::memory_order_acquire);
		if (prev_owner == 0 || prev_owner == tid) {
			m->recursion++;
			// inside the lock
			return;
		}
		futex_wait(&m->owner, prev_owner);
	}
}
gb_internal bool mutex_try_lock(RecursiveMutex *m) {
	Futex tid;
	tid.store(cast(i32)thread_current_id());
	i32 prev_owner = 0;
	m->owner.compare_exchange_strong(prev_owner, tid, std::memory_order_acquire, std::memory_order_acquire);
	if (prev_owner == 0 || prev_owner == tid) {
		m->recursion++;
		// inside the lock
		return true;
	}
	return false;
}
gb_internal void mutex_unlock(RecursiveMutex *m) {
	m->recursion--;
	if (m->recursion != 0) {
		return;
	}
	m->owner.exchange(0, std::memory_order_release);
	futex_signal(&m->owner);
	// outside the lock
}

struct Semaphore {
	Footex count_;
	Futex &count() noexcept {
		return *(Futex *)&this->count_;
	}
	Futex const &count() const noexcept {
		return *(Futex *)&this->count_;
	}
};

gb_internal void semaphore_post(Semaphore *s, i32 count) {
	s->count().fetch_add(count, std::memory_order_release);
	if (s->count().load() == 1) {
		futex_signal(&s->count());
	} else {
		futex_broadcast(&s->count());
	}
}
gb_internal void semaphore_wait(Semaphore *s) {
	for (;;) {
		i32 original_count = s->count().load(std::memory_order_relaxed);
		while (original_count == 0) {
			futex_wait(&s->count(), original_count);
			original_count = s->count().load(std::memory_order_relaxed);
		}

		if (s->count().compare_exchange_strong(original_count, original_count-1, std::memory_order_acquire, std::memory_order_acquire)) {
			return;
		}
	}
}

#if defined(GB_SYSTEM_WINDOWS)
	struct BlockingMutex {
		SRWLOCK srwlock;
	};
	gb_internal void mutex_lock(BlockingMutex *m) {
		AcquireSRWLockExclusive(&m->srwlock);
	}
	gb_internal bool mutex_try_lock(BlockingMutex *m) {
		return !!TryAcquireSRWLockExclusive(&m->srwlock);
	}
	gb_internal void mutex_unlock(BlockingMutex *m) {
		ReleaseSRWLockExclusive(&m->srwlock);
	}

	struct Condition {
		CONDITION_VARIABLE cond;
	};

	gb_internal void condition_broadcast(Condition *c) {
		WakeAllConditionVariable(&c->cond);
	}
	gb_internal void condition_signal(Condition *c) {
		WakeConditionVariable(&c->cond);
	}
	gb_internal void condition_wait(Condition *c, BlockingMutex *m) {
		SleepConditionVariableSRW(&c->cond, &m->srwlock, INFINITE, 0);
	}

	struct RwMutex {
		SRWLOCK srwlock;
	};

	gb_internal void rw_mutex_lock(RwMutex *m) {
		AcquireSRWLockExclusive(&m->srwlock);
	}
	gb_internal bool rw_mutex_try_lock(RwMutex *m) {
		return !!TryAcquireSRWLockExclusive(&m->srwlock);
	}
	gb_internal void rw_mutex_unlock(RwMutex *m) {
		ReleaseSRWLockExclusive(&m->srwlock);
	}

	gb_internal void rw_mutex_shared_lock(RwMutex *m) {
		AcquireSRWLockShared(&m->srwlock);
	}
	gb_internal bool rw_mutex_try_shared_lock(RwMutex *m) {
		return !!TryAcquireSRWLockShared(&m->srwlock);
	}
	gb_internal void rw_mutex_shared_unlock(RwMutex *m) {
		ReleaseSRWLockShared(&m->srwlock);
	}
#else
	enum Internal_Mutex_State : i32 {
		Internal_Mutex_State_Unlocked = 0,
		Internal_Mutex_State_Locked   = 1,
		Internal_Mutex_State_Waiting  = 2,
	};

	struct BlockingMutex {
		#if defined(HAS_VALGRIND)
		// BlockingMutex() {
		// 	VALGRIND_HG_MUTEX_INIT_POST(this, 0);
		// }
		// ~BlockingMutex() {
		// 	VALGRIND_HG_MUTEX_DESTROY_PRE(this);
		// }
		#endif
		i32 state_;

		Futex &state() {
			return *(Futex *)&this->state_;
		}
		Futex const &state() const {
			return *(Futex const *)&this->state_;
		}
	};

	gb_no_inline gb_internal void mutex_lock_slow(BlockingMutex *m, i32 curr_state) {
		i32 new_state = curr_state;
		for (i32 spin = 0; spin < 100; spin++) {
			i32 state = Internal_Mutex_State_Unlocked;
			bool ok = m->state().compare_exchange_weak(state, new_state, std::memory_order_acquire, std::memory_order_consume);
			if (ok) {
				return;
			}
			if (state == Internal_Mutex_State_Waiting) {
				break;
			}
			for (i32 i = gb_min(spin+1, 32); i > 0; i--) {
				yield_thread();
			}
		}

		// Set just in case 100 iterations did not do it
		new_state = Internal_Mutex_State_Waiting;

		for (;;) {
			if (m->state().exchange(Internal_Mutex_State_Waiting, std::memory_order_acquire) == Internal_Mutex_State_Unlocked) {
				return;
			}
			futex_wait(&m->state(), new_state);
			yield_thread();
		}
	}

	gb_internal void mutex_lock(BlockingMutex *m) {
		ANNOTATE_LOCK_PRE(m, 0);
		i32 v = m->state().exchange(Internal_Mutex_State_Locked, std::memory_order_acquire);
		if (v != Internal_Mutex_State_Unlocked) {
			mutex_lock_slow(m, v);
		}
		ANNOTATE_LOCK_POST(m);
	}
	gb_internal bool mutex_try_lock(BlockingMutex *m) {
		ANNOTATE_LOCK_PRE(m, 1);
		i32 v = m->state().exchange(Internal_Mutex_State_Locked, std::memory_order_acquire);
		if (v == Internal_Mutex_State_Unlocked) {
			ANNOTATE_LOCK_POST(m);
			return true;
		}
		return false;
	}

	gb_no_inline gb_internal void mutex_unlock_slow(BlockingMutex *m) {
		futex_signal(&m->state());
	}

	gb_internal void mutex_unlock(BlockingMutex *m) {
		ANNOTATE_UNLOCK_PRE(m);
		i32 v = m->state().exchange(Internal_Mutex_State_Unlocked, std::memory_order_release);
		switch (v) {
		case Internal_Mutex_State_Unlocked:
			GB_PANIC("Unreachable");
			break;
		case Internal_Mutex_State_Locked:
			// Okay
			break;
		case Internal_Mutex_State_Waiting:
			mutex_unlock_slow(m);
			break;
		}
		ANNOTATE_UNLOCK_POST(m);
	}

	struct Condition {
		i32 state_;

		Futex &state() {
			return *(Futex *)&this->state_;
		}
		Futex const &state() const {
			return *(Futex const *)&this->state_;
		}
	};

	gb_internal void condition_broadcast(Condition *c) {
		c->state().fetch_add(1, std::memory_order_release);
		futex_broadcast(&c->state());
	}
	gb_internal void condition_signal(Condition *c) {
		c->state().fetch_add(1, std::memory_order_release);
		futex_signal(&c->state());
	}
	gb_internal void condition_wait(Condition *c, BlockingMutex *m) {
		i32 state = c->state().load(std::memory_order_relaxed);
		mutex_unlock(m);
		futex_wait(&c->state(), state);
		mutex_lock(m);
	}

	struct RwMutex {
		// TODO(bill): make this a proper RW mutex
		BlockingMutex mutex;
	};

	gb_internal void rw_mutex_lock(RwMutex *m) {
		mutex_lock(&m->mutex);
	}
	gb_internal bool rw_mutex_try_lock(RwMutex *m) {
		return mutex_try_lock(&m->mutex);
	}
	gb_internal void rw_mutex_unlock(RwMutex *m) {
		mutex_unlock(&m->mutex);
	}

	gb_internal void rw_mutex_shared_lock(RwMutex *m) {
		mutex_lock(&m->mutex);
	}
	gb_internal bool rw_mutex_try_shared_lock(RwMutex *m) {
		return mutex_try_lock(&m->mutex);
	}
	gb_internal void rw_mutex_shared_unlock(RwMutex *m) {
		mutex_unlock(&m->mutex);
	}
#endif

struct Parker {
	Futex state;
};
enum ParkerState : u32 {
	ParkerState_Empty    = 0,
	ParkerState_Notified = 1,
	ParkerState_Parked   = UINT32_MAX,
};

gb_internal void park(Parker *p) {
	if (p->state.fetch_sub(1, std::memory_order_acquire) == ParkerState_Notified) {
		return;
	}
	for (;;) {
		futex_wait(&p->state, ParkerState_Parked);
		i32 notified = ParkerState_Empty;
		if (p->state.compare_exchange_strong(notified, ParkerState_Empty, std::memory_order_acquire, std::memory_order_acquire)) {
			return;
		}
	}
}

gb_internal void unpark_one(Parker *p) {
	if (p->state.exchange(ParkerState_Notified, std::memory_order_release) == ParkerState_Parked) {
		futex_signal(&p->state);
	}
}

gb_internal void unpark_all(Parker *p) {
	if (p->state.exchange(ParkerState_Notified, std::memory_order_release) == ParkerState_Parked) {
		futex_broadcast(&p->state);
	}
}


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
#elif defined(GB_SYSTEM_HAIKU)
	thread_id = find_thread(NULL);
#elif defined(GB_SYSTEM_FREEBSD)
	thread_id = pthread_getthreadid_np();
#elif defined(GB_SYSTEM_NETBSD)
	thread_id = (u32)_lwp_self();
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

gb_internal TaskRingBuffer *task_ring_init(isize size) {
	TaskRingBuffer *ring = gb_alloc_item(heap_allocator(), TaskRingBuffer);
	ring->size = size;
	ring->buffer = gb_alloc_array(heap_allocator(), WorkerTask, ring->size);
	return ring;
}

gb_internal void thread_queue_destroy(TaskQueue *q) {
	gb_free(heap_allocator(), (*q->ring).buffer);
	gb_free(heap_allocator(), q->ring);
}

gb_internal void thread_init_arenas(Thread *t);

gb_internal void thread_init(ThreadPool *pool, Thread *t, isize idx) {
	gb_zero_item(t);
#if defined(GB_SYSTEM_WINDOWS)
	t->win32_handle = INVALID_HANDLE_VALUE;
#else
	t->posix_handle = 0;
#endif

	// Size must be a power of 2
	t->queue.ring = task_ring_init(1 << 14);
	t->pool = pool;
	t->idx = idx;

	thread_init_arenas(t);
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

	thread_queue_destroy(&t->queue);
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
#elif defined(GB_SYSTEM_NETBSD)
	pthread_setname_np(t->posix_handle, "%s", (void*)name);
#else
	// TODO(bill): Test if this works
	pthread_setname_np(t->posix_handle, name);
#endif
}

#if defined(GB_SYSTEM_LINUX) || defined(GB_SYSTEM_NETBSD)

#include <sys/syscall.h>
#ifdef GB_SYSTEM_LINUX
	#include <linux/futex.h>
#else
	#include <sys/futex.h>
	#define SYS_futex SYS___futex
#endif

gb_internal void futex_signal(Futex *addr) {
	int ret = syscall(SYS_futex, addr, FUTEX_WAKE | FUTEX_PRIVATE_FLAG, 1, NULL, NULL, 0);
	if (ret == -1) {
		perror("Futex wake");
		GB_PANIC("Failed in futex wake!\n");
	}
}

gb_internal void futex_broadcast(Futex *addr) {
	int ret = syscall(SYS_futex, addr, FUTEX_WAKE | FUTEX_PRIVATE_FLAG, INT32_MAX, NULL, NULL, 0);
	if (ret == -1) {
		perror("Futex wake");
		GB_PANIC("Failed in futex wake!\n");
	}
}

gb_internal void futex_wait(Futex *addr, Footex val) {
	for (;;) {
		int ret = syscall(SYS_futex, addr, FUTEX_WAIT | FUTEX_PRIVATE_FLAG, val, NULL, NULL, 0);
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

gb_internal void futex_signal(Futex *addr) {
	_umtx_op(addr, UMTX_OP_WAKE, 1, 0, 0);
}

gb_internal void futex_broadcast(Futex *addr) {
	_umtx_op(addr, UMTX_OP_WAKE, INT32_MAX, 0, 0);
}

gb_internal void futex_wait(Futex *addr, Footex val) {
	for (;;) {
		int ret = _umtx_op(addr, UMTX_OP_WAIT_UINT, val, 0, NULL);
		if (ret == -1) {
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

#elif defined(GB_SYSTEM_OPENBSD)

#include <sys/futex.h>

gb_internal void futex_signal(Futex *f) {
	for (;;) {
		int ret = futex((volatile uint32_t *)f, FUTEX_WAKE | FUTEX_PRIVATE_FLAG, 1, NULL, NULL);
		if (ret == -1) {
			if (errno == ETIMEDOUT || errno == EINTR) {
				continue;
			}

			perror("Futex wake");
			GB_PANIC("futex wake fail");
		} else if (ret == 1) {
			return;
		}
	}
}


gb_internal void futex_broadcast(Futex *f) {
	for (;;) {
		int ret = futex((volatile uint32_t *)f, FUTEX_WAKE | FUTEX_PRIVATE_FLAG, INT32_MAX, NULL, NULL);
		if (ret == -1) {
			if (errno == ETIMEDOUT || errno == EINTR) {
				continue;
			}

			perror("Futex wake");
			GB_PANIC("futex wake fail");
		} else if (ret == 1) {
			return;
		}
	}
}

gb_internal void futex_wait(Futex *f, Footex val) {
	for (;;) {
		int ret = futex((volatile uint32_t *)f, FUTEX_WAIT | FUTEX_PRIVATE_FLAG, val, NULL, NULL);
		if (ret == -1) {
			if (*f != val) {
				return;
			}

			if (errno == ETIMEDOUT || errno == EINTR) {
				continue;
			}

			perror("Futex wait");
			GB_PANIC("Failed in futex wait!\n");
		}
	}
}

#elif defined(GB_SYSTEM_OSX)

// IMPORTANT NOTE(laytan): We use `OS_SYNC_*_SHARED` and `UL_COMPARE_AND_WAIT_SHARED` flags here.
// these flags tell the kernel that we are using these futexes across different processes which
// causes it to opt-out of some optimisations.
//
// BUT this is not actually the case! We should be using the normal non-shared version and letting
// the kernel optimize (I've measured it to be about 10% faster at the parsing/type checking stages).
//
// However we have reports of people on MacOS running into kernel panics, and this seems to fix it for them.
// Which means there is probably a bug in the kernel in one of these non-shared optimisations causing the panic.
//
// The panic also doesn't seem to happen on normal M1 CPUs, and happen more on later CPUs or pro/max series.
// Probably because they have more going on in terms of threads etc.

#if __has_include(<os/os_sync_wait_on_address.h>)
	#define DARWIN_WAIT_ON_ADDRESS_AVAILABLE
	#include <os/os_sync_wait_on_address.h>
#endif

#define UL_COMPARE_AND_WAIT        0x00000001
#define UL_COMPARE_AND_WAIT_SHARED 0x00000003
#define ULF_NO_ERRNO               0x01000000

extern "C" int __ulock_wait(uint32_t operation, void *addr, uint64_t value, uint32_t timeout); /* timeout is specified in microseconds */
extern "C" int __ulock_wake(uint32_t operation, void *addr, uint64_t wake_value);

gb_internal void futex_signal(Futex *f) {
	#ifdef DARWIN_WAIT_ON_ADDRESS_AVAILABLE
	if (__builtin_available(macOS 14.4, *)) {
		for (;;) {
			int ret = os_sync_wake_by_address_any(f, sizeof(Futex), OS_SYNC_WAKE_BY_ADDRESS_SHARED);
			if (ret >= 0) {
				return;
			}
			if (errno == EINTR || errno == EFAULT) {
				continue;
			}
			if (errno == ENOENT) {
				return;
			}
			GB_PANIC("Failed in futex wake %d %d!\n", ret, errno);
		}
	} else {
	#endif
	for (;;) {
		int ret = __ulock_wake(UL_COMPARE_AND_WAIT_SHARED | ULF_NO_ERRNO, f, 0);
		if (ret >= 0) {
			return;
		}
		if (ret == -EINTR || ret == -EFAULT) {
			continue;
		}
		if (ret == -ENOENT) {
			return;
		}
		GB_PANIC("Failed in futex wake!\n");
	}
	#ifdef DARWIN_WAIT_ON_ADDRESS_AVAILABLE
	}
	#endif
}

gb_internal void futex_broadcast(Futex *f) {
	#ifdef DARWIN_WAIT_ON_ADDRESS_AVAILABLE
	if (__builtin_available(macOS 14.4, *)) {
		for (;;) {
			int ret = os_sync_wake_by_address_all(f, sizeof(Footex), OS_SYNC_WAKE_BY_ADDRESS_SHARED);
			if (ret >= 0) {
				return;
			}
			if (errno == EINTR || errno == EFAULT) {
				continue;
			}
			if (errno == ENOENT) {
				return;
			}
			GB_PANIC("Failed in futext wake %d %d!\n", ret, errno);
		}
	} else {
	#endif
	for (;;) {
		enum { ULF_WAKE_ALL = 0x00000100 };
		int ret = __ulock_wake(UL_COMPARE_AND_WAIT_SHARED | ULF_NO_ERRNO | ULF_WAKE_ALL, f, 0);
		if (ret == 0) {
			return;
		}
		if (ret == -EINTR || ret == -EFAULT) {
			continue;
		}
		if (ret == -ENOENT) {
			return;
		}
		GB_PANIC("Failed in futex wake!\n");
	}
	#ifdef DARWIN_WAIT_ON_ADDRESS_AVAILABLE
	}
	#endif
}

gb_internal void futex_wait(Futex *f, Footex val) {
	#ifdef DARWIN_WAIT_ON_ADDRESS_AVAILABLE
	if (__builtin_available(macOS 14.4, *)) {
		for (;;) {
			int ret = os_sync_wait_on_address(f, cast(uint64_t)(val), sizeof(Footex), OS_SYNC_WAIT_ON_ADDRESS_SHARED);
			if (ret >= 0) {
				if (*f != val) {
					return;
				}
				continue;
			}
			if (errno == EINTR || errno == EFAULT) {
				continue;
			}
			if (errno == ENOENT) {
				return;
			}
			GB_PANIC("Failed in futex wait %d %d!\n", ret, errno);
		}
	} else {
	#endif
	for (;;) {
		int ret = __ulock_wait(UL_COMPARE_AND_WAIT_SHARED | ULF_NO_ERRNO, f, val, 0);
		if (ret >= 0) {
			if (*f != val) {
				return;
			}
			continue;
		}
		if (ret == -EINTR || ret == -EFAULT) {continue;
			ret = -ret;
		}
		if (ret == -ENOENT) {
			return;
		}

		GB_PANIC("Failed in futex wait!\n");
	}
	#ifdef DARWIN_WAIT_ON_ADDRESS_AVAILABLE
	}
	#endif
}

#elif defined(GB_SYSTEM_WINDOWS)

gb_internal void futex_signal(Futex *f) {
	WakeByAddressSingle(f);
}

gb_internal void futex_broadcast(Futex *f) {
	WakeByAddressAll(f);
}

gb_internal void futex_wait(Futex *f, Footex val) {
	do {
		WaitOnAddress(f, (void *)&val, sizeof(val), INFINITE);
	} while (f->load() == val);
}

#elif defined(GB_SYSTEM_HAIKU)

// Futex implementation taken from https://tavianator.com/2023/futex.html

#include <pthread.h>
#include <atomic>

struct _Spinlock {
	std::atomic_flag state;

	void init() {
		state.clear();
	}

	void lock() {
		while (state.test_and_set(std::memory_order_acquire)) {
			#if defined(GB_CPU_X86)
			_mm_pause();
			#else
			(void)0; // spin...
			#endif
		}
	}

	void unlock() {
		state.clear(std::memory_order_release);
	}
};

struct Futex_Waitq;
 
struct Futex_Waiter {
	_Spinlock lock;
	pthread_t thread;
	Futex *futex;
	Futex_Waitq *waitq;
	Futex_Waiter *prev, *next;	
};
 
struct Futex_Waitq {
	_Spinlock lock;
	Futex_Waiter list;
 
	void init() {
		auto head = &list;
		head->prev = head->next = head;
	}
};

// FIXME: This approach may scale badly in the future,
// possible solution - hash map (leads to deadlocks now).
 
Futex_Waitq g_waitq = {
	.lock = ATOMIC_FLAG_INIT,
	.list = {
		.prev = &g_waitq.list,
		.next = &g_waitq.list,
	},
};
 
Futex_Waitq *get_waitq(Futex *f) {
	// Future hash map method...
	return &g_waitq;
}
 
void futex_signal(Futex *f) {
	auto waitq = get_waitq(f);
 
	waitq->lock.lock();
 
	auto head = &waitq->list;
	for (auto waiter = head->next; waiter != head; waiter = waiter->next) {
		if (waiter->futex != f) {
			continue;
		}
		waitq->lock.unlock();
		pthread_kill(waiter->thread, SIGCONT);
		return;
	}
 
	waitq->lock.unlock();
}
 
void futex_broadcast(Futex *f) {
	auto waitq = get_waitq(f);
 
	waitq->lock.lock();
 
	auto head = &waitq->list;
	for (auto waiter = head->next; waiter != head; waiter = waiter->next) {
		if (waiter->futex != f) {
			continue;
		}
		if (waiter->next == head) {
			waitq->lock.unlock();
			pthread_kill(waiter->thread, SIGCONT);
			return;
		} else {
			pthread_kill(waiter->thread, SIGCONT);
		}
	}
 
	waitq->lock.unlock();
}
 
void futex_wait(Futex *f, Footex val) {
	Futex_Waiter waiter;
	waiter.thread = pthread_self();
	waiter.futex = f;

	auto waitq = get_waitq(f);
	while (waitq->lock.state.test_and_set(std::memory_order_acquire)) {
		if (f->load(std::memory_order_relaxed) != val) {
			return;
		}
		#if defined(GB_CPU_X86)
		_mm_pause();
		#else
		(void)0; // spin...
		#endif
	}

	waiter.waitq = waitq;
	waiter.lock.init();
	waiter.lock.lock();
 
	auto head = &waitq->list;
	waiter.prev = head->prev;
	waiter.next = head;
	waiter.prev->next = &waiter;
	waiter.next->prev = &waiter;
 
	waiter.prev->next = &waiter;
	waiter.next->prev = &waiter;
 
	sigset_t old_mask, mask;
	sigemptyset(&mask);
	sigaddset(&mask, SIGCONT);
	pthread_sigmask(SIG_BLOCK, &mask, &old_mask);

	if (f->load(std::memory_order_relaxed) == val) {
			waiter.lock.unlock();
			waitq->lock.unlock();

			int sig;
			sigwait(&mask, &sig);

			waitq->lock.lock();
			waiter.lock.lock();

			while (waitq != waiter.waitq) {
				auto req = waiter.waitq;
				waiter.lock.unlock();
				waitq->lock.unlock();
				waitq = req;
				waitq->lock.lock();
				waiter.lock.lock();
			}
	}
 
	waiter.prev->next = waiter.next;
	waiter.next->prev = waiter.prev;
 
	pthread_sigmask(SIG_SETMASK, &old_mask, NULL);
 
	waiter.lock.unlock();
	waitq->lock.unlock();
}

#endif

#if defined(GB_SYSTEM_WINDOWS)
	#pragma warning(pop)
#endif
