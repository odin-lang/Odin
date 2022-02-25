//+build openbsd
package unix

import "core:c"

pthread_t             :: distinct rawptr
pthread_attr_t        :: distinct rawptr
pthread_mutex_t       :: distinct rawptr
pthread_mutexattr_t   :: distinct rawptr
pthread_cond_t        :: distinct rawptr
pthread_condattr_t    :: distinct rawptr
pthread_rwlock_t      :: distinct rawptr
pthread_rwlockattr_t  :: distinct rawptr
pthread_barrier_t     :: distinct rawptr
pthread_barrierattr_t :: distinct rawptr
pthread_spinlock_t    :: distinct rawptr

pthread_key_t  :: distinct c.int
pthread_once_t :: struct {
	state: c.int,
	mutex: pthread_mutex_t,
}

PTHREAD_MUTEX_ERRORCHECK :: 1
PTHREAD_MUTEX_RECURSIVE  :: 2
PTHREAD_MUTEX_NORMAL     :: 3
PTHREAD_MUTEX_STRICT_NP  :: 4

PTHREAD_DETACHED      :: 0x1
PTHREAD_SCOPE_SYSTEM  :: 0x2
PTHREAD_INHERIT_SCHED :: 0x4
PTHREAD_NOFLOAT       :: 0x8

PTHREAD_CREATE_DETACHED :: PTHREAD_DETACHED
PTHREAD_CREATE_JOINABLE :: 0
PTHREAD_SCOPE_PROCESS   :: 0
PTHREAD_EXPLICIT_SCHED  :: 0

SCHED_FIFO  :: 1
SCHED_OTHER :: 2
SCHED_RR    :: 3

sched_param :: struct {
	sched_priority: c.int,
}

sem_t :: distinct rawptr

foreign import libc "system:c"

@(default_calling_convention="c")
foreign libc {
	sem_open :: proc(name: cstring, flags: c.int) -> ^sem_t ---

	sem_init :: proc(sem: ^sem_t, pshared: c.int, initial_value: c.uint) -> c.int ---
	sem_destroy :: proc(sem: ^sem_t) -> c.int ---
	sem_post :: proc(sem: ^sem_t) -> c.int ---
	sem_wait :: proc(sem: ^sem_t) -> c.int ---
	sem_trywait :: proc(sem: ^sem_t) -> c.int ---
	//sem_timedwait :: proc(sem: ^sem_t, timeout: time.TimeSpec) -> c.int ---

	// NOTE: unclear whether pthread_yield is well-supported on Linux systems,
	// see https://linux.die.net/man/3/pthread_yield
	pthread_yield :: proc() ---
}
