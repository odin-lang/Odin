package unix;

import "core:c"

// NOTE(tetra): No 32-bit Macs.
// Source: _pthread_types.h on my Mac.
PTHREAD_SIZE           :: 8176;
PTHREAD_ATTR_SIZE      :: 56;
PTHREAD_MUTEXATTR_SIZE :: 8;
PTHREAD_MUTEX_SIZE     :: 56;
PTHREAD_CONDATTR_SIZE  :: 8;
PTHREAD_COND_SIZE      :: 40;
PTHREAD_ONCE_SIZE      :: 8;
PTHREAD_RWLOCK_SIZE    :: 192;
PTHREAD_RWLOCKATTR_SIZE :: 16;

pthread_t :: opaque struct #align 16 {
	sig: c.long,
	cleanup_stack: rawptr,
	_: [PTHREAD_SIZE] c.char,
};

pthread_attr_t :: opaque struct #align 16 {
	sig: c.long,
	_: [PTHREAD_ATTR_SIZE] c.char,
};

pthread_cond_t :: opaque struct #align 16 {
	sig: c.long,
	_: [PTHREAD_COND_SIZE] c.char,
};

pthread_condattr_t :: opaque struct #align 16 {
	sig: c.long,
	_: [PTHREAD_CONDATTR_SIZE] c.char,
};

pthread_mutex_t :: opaque struct #align 16 {
	sig: c.long,
	_: [PTHREAD_MUTEX_SIZE] c.char,
};

pthread_mutexattr_t :: opaque struct #align 16 {
	sig: c.long,
	_: [PTHREAD_MUTEXATTR_SIZE] c.char,
};

pthread_once_t :: opaque struct #align 16 {
	sig: c.long,
	_: [PTHREAD_ONCE_SIZE] c.char,
};

pthread_rwlock_t :: opaque struct #align 16 {
	sig: c.long,
	_: [PTHREAD_RWLOCK_SIZE] c.char,
};

pthread_rwlockattr_t :: opaque struct #align 16 {
	sig: c.long,
	_: [PTHREAD_RWLOCKATTR_SIZE] c.char,
};

SCHED_OTHER :: 1; // Avoid if you are writing portable software.
SCHED_FIFO  :: 4;
SCHED_RR :: 2; // Round robin.

SCHED_PARAM_SIZE :: 4;

sched_param :: struct {
	sched_priority: c.int,
	_: [SCHED_PARAM_SIZE] c.char,
};

// Source: https://github.com/apple/darwin-libpthread/blob/03c4628c8940cca6fd6a82957f683af804f62e7f/pthread/pthread.h#L138
PTHREAD_CREATE_JOINABLE :: 1;
PTHREAD_CREATE_DETACHED :: 2;
PTHREAD_INHERIT_SCHED :: 1;
PTHREAD_EXPLICIT_SCHED :: 2;
PTHREAD_PROCESS_SHARED :: 1;
PTHREAD_PROCESS_PRIVATE :: 2;
