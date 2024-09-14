#+build freebsd
package unix

import "core:c"

pthread_t :: distinct u64
// pthread_t :: struct #align(16) { x: u64 }

PTHREAD_COND_T_SIZE :: 8

PTHREAD_MUTEXATTR_T_SIZE :: 8
PTHREAD_CONDATTR_T_SIZE  :: 8
PTHREAD_RWLOCKATTR_T_SIZE  :: 8
PTHREAD_BARRIERATTR_T_SIZE :: 8

// WARNING: The sizes of these things are different yet again
// on non-X86!
when size_of(int) == 8 {
	PTHREAD_ATTR_T_SIZE  :: 8
	PTHREAD_MUTEX_T_SIZE :: 8
	PTHREAD_RWLOCK_T_SIZE  :: 8
	PTHREAD_BARRIER_T_SIZE :: 8
} else when size_of(int) == 4 { // TODO
	PTHREAD_ATTR_T_SIZE  :: 32
	PTHREAD_MUTEX_T_SIZE :: 32
	PTHREAD_RWLOCK_T_SIZE  :: 44
	PTHREAD_BARRIER_T_SIZE :: 20
}

pthread_cond_t :: struct #align(16) {
	_: [PTHREAD_COND_T_SIZE] c.char,
}
pthread_mutex_t :: struct #align(16) {
	_: [PTHREAD_MUTEX_T_SIZE] c.char,
}
pthread_rwlock_t :: struct #align(16) {
	_: [PTHREAD_RWLOCK_T_SIZE] c.char,
}
pthread_barrier_t :: struct #align(16) {
	_: [PTHREAD_BARRIER_T_SIZE] c.char,
}

pthread_attr_t :: struct #align(16) {
	_: [PTHREAD_ATTR_T_SIZE] c.char,
}
pthread_condattr_t :: struct #align(16) {
	_: [PTHREAD_CONDATTR_T_SIZE] c.char,
}
pthread_mutexattr_t :: struct #align(16) {
	_: [PTHREAD_MUTEXATTR_T_SIZE] c.char,
}
pthread_rwlockattr_t :: struct #align(16) {
	_: [PTHREAD_RWLOCKATTR_T_SIZE] c.char,
}
pthread_barrierattr_t :: struct #align(16) {
	_: [PTHREAD_BARRIERATTR_T_SIZE] c.char,
}

PTHREAD_MUTEX_ERRORCHECK :: 1
PTHREAD_MUTEX_RECURSIVE :: 2
PTHREAD_MUTEX_NORMAL :: 3


PTHREAD_CREATE_JOINABLE :: 0
PTHREAD_CREATE_DETACHED :: 1
PTHREAD_INHERIT_SCHED :: 4
PTHREAD_EXPLICIT_SCHED :: 0
PTHREAD_PROCESS_PRIVATE :: 0
PTHREAD_PROCESS_SHARED :: 1

SCHED_FIFO  :: 1
SCHED_OTHER :: 2
SCHED_RR :: 3 // Round robin.


sched_param :: struct {
	sched_priority: c.int,
}

_usem :: struct {
	_has_waiters: u32,
	_count: u32,
	_flags: u32,
}
_usem2 :: struct {
	_count: u32,
	_flags: u32,
}
sem_t :: struct {
	_magic: u32,
	_kern: _usem2,
	_padding: u32,
}

PTHREAD_CANCEL_ENABLE       :: 0
PTHREAD_CANCEL_DISABLE      :: 1
PTHREAD_CANCEL_DEFERRED     :: 0
PTHREAD_CANCEL_ASYNCHRONOUS :: 2

foreign import "system:pthread"

@(default_calling_convention="c")
foreign pthread {
	// create named semaphore.
	// used in process-shared semaphores.
	sem_open :: proc(name: cstring, flags: c.int) -> ^sem_t ---

	sem_init :: proc(sem: ^sem_t, pshared: c.int, initial_value: c.uint) -> c.int ---
	sem_destroy :: proc(sem: ^sem_t) -> c.int ---
	sem_post :: proc(sem: ^sem_t) -> c.int ---
	sem_wait :: proc(sem: ^sem_t) -> c.int ---
	sem_trywait :: proc(sem: ^sem_t) -> c.int ---
	// sem_timedwait :: proc(sem: ^sem_t, timeout: time.TimeSpec) -> c.int ---

	// NOTE: unclear whether pthread_yield is well-supported on Linux systems,
	// see https://linux.die.net/man/3/pthread_yield
	pthread_yield :: proc() ---

	pthread_setcancelstate :: proc (state: c.int, old_state: ^c.int) -> c.int ---
	pthread_setcanceltype  :: proc (type:  c.int, old_type:  ^c.int) -> c.int ---
	pthread_cancel         :: proc (thread: pthread_t) -> c.int ---
}
