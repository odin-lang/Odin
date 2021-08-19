struct BlockingMutex;
struct RecursiveMutex;
struct Semaphore;
struct Thread;

#define THREAD_PROC(name) isize name(struct Thread *thread)
typedef THREAD_PROC(ThreadProc);

struct Thread {
#if defined(GB_SYSTEM_WINDOWS)
	void *        win32_handle;
#else
	pthread_t     posix_handle;
#endif

	ThreadProc * proc;
	void *         user_data;
	isize          user_index;
	isize volatile return_value;

	Semaphore     *semaphore;
	isize          stack_size;
	b32 volatile   is_running;
};


void mutex_init    (BlockingMutex *m);
void mutex_destroy (BlockingMutex *m);
void mutex_lock    (BlockingMutex *m);
bool mutex_try_lock(BlockingMutex *m);
void mutex_unlock  (BlockingMutex *m);
void mutex_init    (RecursiveMutex *m);
void mutex_destroy (RecursiveMutex *m);
void mutex_lock    (RecursiveMutex *m);
bool mutex_try_lock(RecursiveMutex *m);
void mutex_unlock  (RecursiveMutex *m);

void semaphore_init   (Semaphore *s);
void semaphore_destroy(Semaphore *s);
void semaphore_post   (Semaphore *s, i32 count);
void semaphore_wait   (Semaphore *s);
void semaphore_release(Semaphore *s) { semaphore_post(s, 1); }

u32  thread_current_id(void);

void thread_init            (Thread *t);
void thread_destroy         (Thread *t);
void thread_start           (Thread *t, ThreadProc *proc, void *data);
void thread_start_with_stack(Thread *t, ThreadProc *proc, void *data, isize stack_size);
void thread_join            (Thread *t);
bool thread_is_running      (Thread const *t);
void thread_set_name        (Thread *t, char const *name);

void yield_thread(void);
void yield_process(void);


#if defined(GB_SYSTEM_WINDOWS)
	struct BlockingMutex {
		SRWLOCK srwlock;
	};
	void mutex_init(BlockingMutex *m) {
	}
	void mutex_destroy(BlockingMutex *m) {
	}
	void mutex_lock(BlockingMutex *m) {
		AcquireSRWLockExclusive(&m->srwlock);
	}
	bool mutex_try_lock(BlockingMutex *m) {
		return !!TryAcquireSRWLockExclusive(&m->srwlock);
	}
	void mutex_unlock(BlockingMutex *m) {
		ReleaseSRWLockExclusive(&m->srwlock);
	}

	struct RecursiveMutex {
		CRITICAL_SECTION win32_critical_section;
	};
	void mutex_init(RecursiveMutex *m) {
		InitializeCriticalSection(&m->win32_critical_section);
	}
	void mutex_destroy(RecursiveMutex *m) {
		DeleteCriticalSection(&m->win32_critical_section);
	}
	void mutex_lock(RecursiveMutex *m) {
		EnterCriticalSection(&m->win32_critical_section);
	}
	bool mutex_try_lock(RecursiveMutex *m) {
		return TryEnterCriticalSection(&m->win32_critical_section) != 0;
	}
	void mutex_unlock(RecursiveMutex *m) {
		LeaveCriticalSection(&m->win32_critical_section);
	}

	struct Semaphore {
		void *win32_handle;
	};

	void semaphore_init(Semaphore *s) {
		s->win32_handle = CreateSemaphoreA(NULL, 0, I32_MAX, NULL);
	}
	void semaphore_destroy(Semaphore *s) {
		CloseHandle(s->win32_handle);
	}
	void semaphore_post(Semaphore *s, i32 count) {
		ReleaseSemaphore(s->win32_handle, count, NULL);
	}
	void semaphore_wait(Semaphore *s) {
		WaitForSingleObjectEx(s->win32_handle, INFINITE, FALSE);
	}

#else
	struct BlockingMutex {
		pthread_mutex_t pthread_mutex;
	};
	void mutex_init(BlockingMutex *m) {
		pthread_mutex_init(&m->pthread_mutex, nullptr);
	}
	void mutex_destroy(BlockingMutex *m) {
		pthread_mutex_destroy(&m->pthread_mutex);
	}
	void mutex_lock(BlockingMutex *m) {
		pthread_mutex_lock(&m->pthread_mutex);
	}
	bool mutex_try_lock(BlockingMutex *m) {
		return pthread_mutex_trylock(&m->pthread_mutex) == 0;
	}
	void mutex_unlock(BlockingMutex *m) {
		pthread_mutex_unlock(&m->pthread_mutex);
	}

	struct RecursiveMutex {
		pthread_mutex_t pthread_mutex;
		pthread_mutexattr_t pthread_mutexattr;
	};
	void mutex_init(RecursiveMutex *m) {
		pthread_mutexattr_init(&m->pthread_mutexattr);
		pthread_mutexattr_settype(&m->pthread_mutexattr, PTHREAD_MUTEX_RECURSIVE);
		pthread_mutex_init(&m->pthread_mutex, &m->pthread_mutexattr);
	}
	void mutex_destroy(RecursiveMutex *m) {
		pthread_mutex_destroy(&m->pthread_mutex);
	}
	void mutex_lock(RecursiveMutex *m) {
		pthread_mutex_lock(&m->pthread_mutex);
	}
	bool mutex_try_lock(RecursiveMutex *m) {
		return pthread_mutex_trylock(&m->pthread_mutex) == 0;
	}
	void mutex_unlock(RecursiveMutex *m) {
		pthread_mutex_unlock(&m->pthread_mutex);
	}

	#if defined(GB_SYSTEM_OSX)
		struct Semaphore {
			semaphore_t osx_handle;
		};

		void semaphore_init   (Semaphore *s)            { semaphore_create(mach_task_self(), &s->osx_handle, SYNC_POLICY_FIFO, 0); }
		void semaphore_destroy(Semaphore *s)            { semaphore_destroy(mach_task_self(), s->osx_handle); }
		void semaphore_post   (Semaphore *s, i32 count) { while (count --> 0) semaphore_signal(s->osx_handle); }
		void semaphore_wait   (Semaphore *s)            { semaphore_wait(s->osx_handle); }
	#elif defined(GB_SYSTEM_UNIX)
		struct Semaphore {
			sem_t unix_handle;
		};

		void semaphore_init   (Semaphore *s)            { sem_init(&s->unix_handle, 0, 0); }
		void semaphore_destroy(Semaphore *s)            { sem_destroy(&s->unix_handle); }
		void semaphore_post   (Semaphore *s, i32 count) { while (count --> 0) sem_post(&s->unix_handle); }
		void semaphore_wait   (Semaphore *s)            { int i; do { i = sem_wait(&s->unix_handle); } while (i == -1 && errno == EINTR); }
	#else
	#error
	#endif
#endif




u32 thread_current_id(void) {
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
#else
	#error Unsupported architecture for thread_current_id()
#endif

	return thread_id;
}


gb_inline void yield_thread(void) {
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
#else
#error Unknown architecture
#endif
}

gb_inline void yield(void) {
#if defined(GB_SYSTEM_WINDOWS)
	YieldProcessor();
#else
	sched_yield();
#endif
}


void thread_init(Thread *t) {
	gb_zero_item(t);
#if defined(GB_SYSTEM_WINDOWS)
	t->win32_handle = INVALID_HANDLE_VALUE;
#else
	t->posix_handle = 0;
#endif
	t->semaphore = gb_alloc_item(heap_allocator(), Semaphore);
	semaphore_init(t->semaphore);
}

void thread_destroy(Thread *t) {
	if (t->is_running) thread_join(t);
	semaphore_destroy(t->semaphore);
	gb_free(heap_allocator(), t->semaphore);
}


void gb__thread_run(Thread *t) {
	semaphore_release(t->semaphore);
	t->return_value = t->proc(t);
}

#if defined(GB_SYSTEM_WINDOWS)
	DWORD __stdcall internal_thread_proc(void *arg) {
		Thread *t = cast(Thread *)arg;
		gb__thread_run(t);
		t->is_running = false;
		return 0;
	}
#else
	void *          internal_thread_proc(void *arg) {
		Thread *t = cast(Thread *)arg;
		gb__thread_run(t);
		t->is_running = false;
		return NULL;
	}
#endif

void thread_start(Thread *t, ThreadProc *proc, void *user_data) { thread_start_with_stack(t, proc, user_data, 0); }

void thread_start_with_stack(Thread *t, ThreadProc *proc, void *user_data, isize stack_size) {
	GB_ASSERT(!t->is_running);
	GB_ASSERT(proc != NULL);
	t->proc = proc;
	t->user_data = user_data;
	t->stack_size = stack_size;
	t->is_running = true;

#if defined(GB_SYSTEM_WINDOWS)
	t->win32_handle = CreateThread(NULL, stack_size, internal_thread_proc, t, 0, NULL);
	GB_ASSERT_MSG(t->win32_handle != NULL, "CreateThread: GetLastError");
#else
	{
		pthread_attr_t attr;
		pthread_attr_init(&attr);
		pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE);
		if (stack_size != 0) {
			pthread_attr_setstacksize(&attr, stack_size);
		}
		pthread_create(&t->posix_handle, &attr, internal_thread_proc, t);
		pthread_attr_destroy(&attr);
	}
#endif

	semaphore_wait(t->semaphore);
}

void thread_join(Thread *t) {
	if (!t->is_running) return;

#if defined(GB_SYSTEM_WINDOWS)
	WaitForSingleObject(t->win32_handle, INFINITE);
	CloseHandle(t->win32_handle);
	t->win32_handle = INVALID_HANDLE_VALUE;
#else
	pthread_join(t->posix_handle, NULL);
	t->posix_handle = 0;
#endif
	t->is_running = false;
}

bool thread_is_running(Thread const *t) { return t->is_running != 0; }

void thread_set_name(Thread *t, char const *name) {
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
#elif defined(GB_SYSTEM_FREEBSD)
	pthread_set_name_np(t->posix_handle, name);
#else
	// TODO(bill): Test if this works
	pthread_setname_np(t->posix_handle, name);
#endif
}

