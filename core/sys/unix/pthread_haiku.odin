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

PTHREAD_MUTEX_DEFAULT    :: 0
PTHREAD_MUTEX_NORMAL     :: 1
PTHREAD_MUTEX_ERRORCHECK :: 2
PTHREAD_MUTEX_RECURSIVE  :: 3

PTHREAD_DETACHED      :: 0x1
PTHREAD_SCOPE_SYSTEM  :: 0x2
PTHREAD_INHERIT_SCHED :: 0x4
PTHREAD_NOFLOAT       :: 0x8

PTHREAD_CREATE_DETACHED :: PTHREAD_DETACHED
PTHREAD_CREATE_JOINABLE :: 0
PTHREAD_SCOPE_PROCESS   :: 0
PTHREAD_EXPLICIT_SCHED  :: 0

SCHED_FIFO     :: 1
SCHED_RR       :: 2
SCHED_SPORADIC :: 3
SCHED_OTHER    :: 4

sched_param :: struct {
	sched_priority: c.int,
}

sem_t :: distinct rawptr

PTHREAD_CANCEL_ENABLE       :: 0
PTHREAD_CANCEL_DISABLE      :: 1
PTHREAD_CANCEL_DEFERRED     :: 0
PTHREAD_CANCEL_ASYNCHRONOUS :: 2

foreign import libc "system:c"

@(default_calling_convention="c")
foreign libc {
	sem_open :: proc(name: cstring, flags: c.int) -> ^sem_t ---

	sem_init :: proc(sem: ^sem_t, pshared: c.int, initial_value: c.uint) -> c.int ---
	sem_destroy :: proc(sem: ^sem_t) -> c.int ---
	sem_post :: proc(sem: ^sem_t) -> c.int ---
	sem_wait :: proc(sem: ^sem_t) -> c.int ---
	sem_trywait :: proc(sem: ^sem_t) -> c.int ---
	
	pthread_yield :: proc() ---

	pthread_setcancelstate :: proc (state: c.int, old_state: ^c.int) -> c.int ---
	pthread_setcanceltype  :: proc (type:  c.int, old_type:  ^c.int) -> c.int ---
	pthread_cancel         :: proc (thread: pthread_t) -> c.int ---
}
