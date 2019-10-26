package unix;

import "core:c"

// TODO(tetra): For robustness, I'd like to mark this with align 16.
// I cannot currently do this.
// And at the time of writing there is a bug with putting it
// as the only field in a struct.
pthread_t :: distinct u64;
// pthread_t :: struct #align 16 { x: u64 };

// NOTE(tetra): Got all the size constants from pthreadtypes-arch.h on my
// Linux machine.

PTHREAD_COND_T_SIZE :: 48;

PTHREAD_MUTEXATTR_T_SIZE :: 4;
PTHREAD_CONDATTR_T_SIZE  :: 4;
PTHREAD_RWLOCKATTR_T_SIZE  :: 8;
PTHREAD_BARRIERATTR_T_SIZE :: 4;

// WARNING: The sizes of these things are different yet again
// on non-X86!
when size_of(int) == 8 {
	PTHREAD_ATTR_T_SIZE  :: 56;
	PTHREAD_MUTEX_T_SIZE :: 40;
	PTHREAD_RWLOCK_T_SIZE  :: 56;
	PTHREAD_BARRIER_T_SIZE :: 32;
} else when size_of(int) == 4 {
	PTHREAD_ATTR_T_SIZE  :: 32;
	PTHREAD_MUTEX_T_SIZE :: 32;
	PTHREAD_RWLOCK_T_SIZE  :: 44;
	PTHREAD_BARRIER_T_SIZE :: 20;
}

pthread_cond_t :: opaque struct #align 16 {
	_: [PTHREAD_COND_T_SIZE] c.char,
};
pthread_mutex_t :: opaque struct #align 16 {
	_: [PTHREAD_MUTEX_T_SIZE] c.char,
};
pthread_rwlock_t :: opaque struct #align 16 {
	_: [PTHREAD_RWLOCK_T_SIZE] c.char,
};
pthread_barrier_t :: opaque struct #align 16 {
	_: [PTHREAD_BARRIER_T_SIZE] c.char,
};

pthread_attr_t :: opaque struct #align 16 {
	_: [PTHREAD_ATTR_T_SIZE] c.char,
};
pthread_condattr_t :: opaque struct #align 16 {
	_: [PTHREAD_CONDATTR_T_SIZE] c.char,
};
pthread_mutexattr_t :: opaque struct #align 16 {
	_: [PTHREAD_MUTEXATTR_T_SIZE] c.char,
};
pthread_rwlockattr_t :: opaque struct #align 16 {
	_: [PTHREAD_RWLOCKATTR_T_SIZE] c.char,
};
pthread_barrierattr_t :: opaque struct #align 16 {
	_: [PTHREAD_BARRIERATTR_T_SIZE] c.char,
};


// TODO(tetra, 2019-11-01): Maybe make `enum c.int`s for these?
PTHREAD_CREATE_JOINABLE :: 0;
PTHREAD_CREATE_DETACHED :: 1;
PTHREAD_INHERIT_SCHED :: 0;
PTHREAD_EXPLICIT_SCHED :: 1;
PTHREAD_PROCESS_PRIVATE :: 0;
PTHREAD_PROCESS_SHARED :: 1;

SCHED_OTHER :: 0;
SCHED_FIFO  :: 1;
SCHED_RR :: 2; // Round robin.

sched_param :: struct {
	sched_priority: c.int,
}

sem_t :: struct #align 16 {
	_: [SEM_T_SIZE] c.char,
}

when size_of(int) == 8 {
	SEM_T_SIZE :: 32;
} else when size_of(int) == 4 {
	SEM_T_SIZE :: 16;
}

foreign import "system:pthread"

@(default_calling_convention="c")
foreign pthread {
	// create named semaphore.
	// used in process-shared semaphores.
	sem_open :: proc(name: cstring, flags: c.int) -> ^sem_t ---;

	sem_init :: proc(sem: ^sem_t, pshared: c.int, initial_value: c.uint) -> c.int ---;
	sem_destroy :: proc(sem: ^sem_t) -> c.int ---;
	sem_post :: proc(sem: ^sem_t) -> c.int ---;
	sem_wait :: proc(sem: ^sem_t) -> c.int ---;
	sem_trywait :: proc(sem: ^sem_t) -> c.int ---;
	// sem_timedwait :: proc(sem: ^sem_t, timeout: time.TimeSpec) -> c.int ---;
}
