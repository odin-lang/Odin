package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else when ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD {
	foreign import lib "system:pthread"
} else {
	foreign import lib "system:c"
}

// pthread.h - threads

// NOTE: mutexes, rwlock, condition variables, once and barriers are left out in favour of `core:sync`.

foreign lib {
	/*
	Initializes a thread attributes object.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_attr_init.html ]]
	*/
	pthread_attr_init :: proc(attr: ^pthread_attr_t) -> Errno ---

	/*
	Destroys a thread attributes object.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_attr_init.html ]]
	*/
	pthread_attr_destroy :: proc(attr: ^pthread_attr_t) -> Errno ---

	/*
	The detachstate attribute controls whether the thread is created in a detached state.
	If the thread is created detached, then use of the ID of the newly created thread is an error.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_attr_getdetachstate.html ]]
	*/
	pthread_attr_getdetachstate :: proc(attr: ^pthread_attr_t, detachstate: ^Detach_State) -> Errno ---

	/*
	The detachstate attribute controls whether the thread is created in a detached state.
	If the thread is created detached, then use of the ID of the newly created thread is an error.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_attr_getdetachstate.html ]]
	*/
	pthread_attr_setdetachstate :: proc(attr: ^pthread_attr_t, detachstate: Detach_State) -> Errno ---

	/*
	The guardsize attribute controls the size of the guard area for the created thread's stack.
	The guardsize attribute provides protection against overflow of the stack pointer.
	If a thread's stack is created with guard protection, the implementation allocates extra memory
	at the overflow end of the stack as a buffer against stack overflow of the stack pointer.
	If an application overflows into this buffer an error shall result (possibly in a SIGSEGV signal being delivered to the thread).

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_attr_setguardsize.html ]]
	*/
	pthread_attr_getguardsize :: proc(attr: ^pthread_attr_t, guardsize: ^c.size_t) -> Errno ---

	/*
	The guardsize attribute controls the size of the guard area for the created thread's stack.
	The guardsize attribute provides protection against overflow of the stack pointer.
	If a thread's stack is created with guard protection, the implementation allocates extra memory
	at the overflow end of the stack as a buffer against stack overflow of the stack pointer.
	If an application overflows into this buffer an error shall result (possibly in a SIGSEGV signal being delivered to the thread).

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_attr_setguardsize.html ]]
	*/
	pthread_attr_setguardsize :: proc(attr: ^pthread_attr_t, guardsize: c.size_t) -> Errno ---

	/*
	When the attributes objects are used by pthread_create(), the inheritsched attribute determines
	how the other scheduling attributes of the created thread shall be set.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_attr_setinheritsched.html ]]
	*/
	pthread_attr_getinheritsched :: proc(attr: ^pthread_attr_t, inheritsched: ^Inherit_Sched) -> Errno ---

	/*
	When the attributes objects are used by pthread_create(), the inheritsched attribute determines
	how the other scheduling attributes of the created thread shall be set.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_attr_setinheritsched.html ]]
	*/
	pthread_attr_setinheritsched :: proc(attr: ^pthread_attr_t, inheritsched: Inherit_Sched) -> Errno ---

	/*
	Gets the scheduling param.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_attr_setschedparam.html ]]
	*/
	pthread_attr_getschedparam :: proc(attr: ^pthread_attr_t, param: ^sched_param) -> Errno ---

	/*
	Sets the scheduling param.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_attr_setschedparam.html ]]
	*/
	pthread_attr_setschedparam :: proc(attr: ^pthread_attr_t, param: ^sched_param) -> Errno ---

	/*
	Gets the scheduling poicy.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_attr_getschedpolicy.html ]]
	*/
	pthread_attr_getschedpolicy :: proc(attr: ^pthread_attr_t, policy: ^Sched_Policy) -> Errno ---

	/*
	Sets the scheduling poicy.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_attr_getschedpolicy.html ]]
	*/
	pthread_attr_setschedpolicy :: proc(attr: ^pthread_attr_t, policy: Sched_Policy) -> Errno ---

	/*
	Gets the contention scope.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_attr_getscope.html ]]
	*/
	pthread_attr_getscope :: proc(attr: ^pthread_attr_t, contentionscope: ^Thread_Scope) -> Errno ---

	/*
	Sets the contention scope.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_attr_getscope.html ]]
	*/
	pthread_attr_setscope :: proc(attr: ^pthread_attr_t, contentionscope: ^Thread_Scope) -> Errno ---

	/*
	Get the area of storage to be used for the created thread's stack.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_attr_getstack.html ]]
	*/
	pthread_attr_getstack :: proc(attr: ^pthread_attr_t, stackaddr: ^[^]byte, stacksize: ^c.size_t) -> Errno ---

	/*
	Specify the area of storage to be used for the created thread's stack.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_attr_getstack.html ]]
	*/
	pthread_attr_setstack :: proc(attr: ^pthread_attr_t, stackaddr: [^]byte, stacksize: c.size_t) -> Errno ---

	/*
	Gets the stack size.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_attr_getstacksize.html ]]
	*/
	pthread_attr_getstacksize :: proc(attr: ^pthread_attr_t, stacksize: ^c.size_t) -> Errno ---

	/*
	Sets the stack size.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_attr_getstacksize.html ]]
	*/
	pthread_attr_setstacksize :: proc(attr: ^pthread_attr_t, stacksize: c.size_t) -> Errno ---

	/*
	Register fork handlers to be called before and after fork().

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_atfork.html ]]
	*/
	pthread_atfork :: proc(prepare: proc "c" (), parent: proc "c" (), child: proc "c" ()) -> Errno ---


	/*
	Cancel the execution of a thread.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_cancel.html ]]
	*/
	pthread_cancel :: proc(thread: pthread_t) -> Errno ---

	/*
	Creates a new thread with the given attributes.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_create.html ]]
	*/
	pthread_create :: proc(
		thread:        ^pthread_t,
		attr:          ^pthread_attr_t,
		start_routine: proc "c" (arg: rawptr) -> rawptr,
		arg:           rawptr,
	) -> Errno ---


	/*
	Indicate that storage for the thread can be reclaimed when the thread terminates.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_detach.html ]]
	*/
	pthread_detach :: proc(thread: pthread_t) -> Errno ---

	/*
	Compare thread IDs.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_equal.html ]]
	*/
	pthread_equal :: proc(t1: pthread_t, t2: pthread_t) -> b32 ---

	/*
	Terminates the calling thread and make the given value available to any successfull join calls.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_exit.html ]]
	*/
	pthread_exit :: proc(value_ptr: rawptr) -> ! ---

	/*
	Gets the current concurrency hint.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_getconcurrency.html ]]
	*/
	pthread_getconcurrency :: proc() -> c.int ---

	/*
	Sets the current desired concurrency hint.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_getconcurrency.html ]]
	*/
	pthread_setconcurrency :: proc(new_level: c.int) -> Errno ---

	/*
	Access a thread CPU-time clock.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_getcpuclockid.html ]]
	*/
	pthread_getcpuclockid :: proc(thread_id: pthread_t, clock_id: ^clockid_t) -> Errno ---

	/*
	Gets the scheduling policy and parameters.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_getschedparam.html ]]
	*/
	pthread_getschedparam :: proc(thread: pthread_t, policy: ^Sched_Policy, param: ^sched_param) -> Errno ---

	/*
	Sets the scheduling policy and parameters.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_getschedparam.html ]]
	*/
	pthread_setschedparam :: proc(thread: pthread_t, policy: Sched_Policy, param: ^sched_param) -> Errno ---

	/*
	Creates a thread-specific data key visible to all threads in the process.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_key_create.html ]]
	*/
	pthread_key_create :: proc(key: ^pthread_key_t, destructor: proc "c" (value: rawptr) = nil) -> Errno ---

	/*
	Deletes a thread-specific data key visible to all threads in the process.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_key_delete.html ]]
	*/
	pthread_key_delete :: proc(key: pthread_key_t) -> Errno ---

	/*
	Returns the value currently bound to the specified key on behalf of the calling thread.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_getspecific.html ]]
	*/
	pthread_getspecific :: proc(key: pthread_key_t) -> rawptr ---

	/*
	Sets the value currently bound to the specified key on behalf of the calling thread.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_getspecific.html ]]
	*/
	pthread_setspecific :: proc(key: pthread_key_t, value: rawptr) -> Errno ---

	/*
	Suspends execution of the calling thread until the target thread terminates.

	Example:
		ar: [10_000]i32

		sb1 := ar[:5_000]
		sb2 := ar[5_000:]

		th1, th2: posix.pthread_t

		posix.pthread_create(&th1, nil, incer, &sb1)
		posix.pthread_create(&th2, nil, incer, &sb2)

		posix.pthread_join(th1)
		posix.pthread_join(th2)

		incer :: proc "c" (arg: rawptr) -> rawptr {
			sb := (^[]i32)(arg)
			for &val in sb {
				val += 1
			}

			return nil
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_join.html ]]
	*/
	pthread_join :: proc(thread: pthread_t, value_ptr: ^rawptr = nil) -> Errno ---

	/*
	Get the calling thread ID.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_self.html ]]
	*/
	pthread_self :: proc() -> pthread_t ---

	/*
	Atomically set the calling thread's cancelability and return the previous value.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_setcancelstate.html ]]
	*/
	pthread_setcancelstate :: proc(state: Cancel_State, oldstate: ^Cancel_State) -> Errno ---

	/*
	Atomically set the calling thread's cancel type and return the previous value.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_setcancelstate.html ]]
	*/
	pthread_setcanceltype :: proc(type: Cancel_Type, oldtype: ^Cancel_Type) -> Errno ---


	/*
	Creates a cancellation point in the calling thread.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_testcancel.html ]]
	*/
	pthread_testcancel :: proc() ---

	/*
	Sets the scheduling priority for the thread given.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_setschedprio.html ]]
	*/
	pthread_setschedprio :: proc(thread: pthread_t, prio: c.int) -> Errno ---
}

Detach_State :: enum c.int {
	// Causes all threads to be in the joinable state.
	CREATE_JOINABLE = PTHREAD_CREATE_JOINABLE,
	// Causes all threads to be in the detached state.
	CREATE_DETACHED = PTHREAD_CREATE_DETACHED,
}

Inherit_Sched :: enum c.int {
	// Threads inherit from the creating thread.
	INHERIT_SCHED  = PTHREAD_INHERIT_SCHED,
	// Threads scheduling shall be set to the corresponding values from the attributes object.
	EXPLICIT_SCHED = PTHREAD_EXPLICIT_SCHED,
}

Thread_Scope :: enum c.int {
	// System scheduling contention scope.
	SYSTEM  = PTHREAD_SCOPE_SYSTEM,
	// Process scheduling contention scope.
	PROCESS = PTHREAD_SCOPE_PROCESS,
}

Cancel_State :: enum c.int {
	ENABLE  = PTHREAD_CANCEL_ENABLE,
	DISABLE = PTHREAD_CANCEL_DISABLE,
}

Cancel_Type :: enum c.int {
	DEFERRED     = PTHREAD_CANCEL_DEFERRED,
	ASYNCHRONOUS = PTHREAD_CANCEL_ASYNCHRONOUS,
}

when ODIN_OS == .Darwin {

	PTHREAD_CANCEL_ASYNCHRONOUS :: 0x00
	PTHREAD_CANCEL_DEFERRED     :: 0x02

	PTHREAD_CANCEL_DISABLE      :: 0x00
	PTHREAD_CANCEL_ENABLE       :: 0x01

	PTHREAD_CANCELED :: rawptr(uintptr(1))

	PTHREAD_CREATE_DETACHED :: 2
	PTHREAD_CREATE_JOINABLE :: 1

	PTHREAD_EXPLICIT_SCHED :: 2
	PTHREAD_INHERIT_SCHED  :: 1

	PTHREAD_PRIO_INHERIT :: 1
	PTHREAD_PRIO_NONE    :: 0
	PTHREAD_PRIO_PROTECT :: 2

	PTHREAD_PROCESS_SHARED  :: 1
	PTHREAD_PROCESS_PRIVATE :: 2

	PTHREAD_SCOPE_PROCESS   :: 2
	PTHREAD_SCOPE_SYSTEM    :: 1

	pthread_t :: distinct u64

	pthread_attr_t :: struct {
		__sig:    c.long,
		__opaque: [56]c.char,
	}

	pthread_key_t :: distinct c.ulong

	sched_param :: struct {
		sched_priority: c.int,     /* [PSX] process or thread execution scheduling priority */
		_:              [4]c.char,
	}

} else when ODIN_OS == .FreeBSD {

	PTHREAD_CANCEL_ASYNCHRONOUS :: 0x02
	PTHREAD_CANCEL_DEFERRED     :: 0x00

	PTHREAD_CANCEL_DISABLE      :: 0x01
	PTHREAD_CANCEL_ENABLE       :: 0x00

	PTHREAD_CANCELED :: rawptr(uintptr(1))

	PTHREAD_CREATE_DETACHED :: 1
	PTHREAD_CREATE_JOINABLE :: 0

	PTHREAD_EXPLICIT_SCHED :: 0
	PTHREAD_INHERIT_SCHED  :: 4

	PTHREAD_PRIO_INHERIT :: 1
	PTHREAD_PRIO_NONE    :: 0
	PTHREAD_PRIO_PROTECT :: 2

	PTHREAD_PROCESS_SHARED  :: 0
	PTHREAD_PROCESS_PRIVATE :: 1

	PTHREAD_SCOPE_PROCESS   :: 0
	PTHREAD_SCOPE_SYSTEM    :: 2

	pthread_t :: distinct u64

	pthread_attr_t :: distinct rawptr

	pthread_key_t :: distinct c.int

	sched_param :: struct {
		sched_priority: c.int,     /* [PSX] process or thread execution scheduling priority */
	}

} else when ODIN_OS == .NetBSD {

	PTHREAD_CANCEL_ASYNCHRONOUS :: 1
	PTHREAD_CANCEL_DEFERRED     :: 0

	PTHREAD_CANCEL_DISABLE      :: 1
	PTHREAD_CANCEL_ENABLE       :: 0

	PTHREAD_CANCELED :: rawptr(uintptr(1))

	PTHREAD_CREATE_DETACHED :: 1
	PTHREAD_CREATE_JOINABLE :: 0

	PTHREAD_EXPLICIT_SCHED :: 1
	PTHREAD_INHERIT_SCHED  :: 0

	PTHREAD_PRIO_INHERIT :: 1
	PTHREAD_PRIO_NONE    :: 0
	PTHREAD_PRIO_PROTECT :: 2

	PTHREAD_PROCESS_SHARED  :: 1
	PTHREAD_PROCESS_PRIVATE :: 0

	PTHREAD_SCOPE_PROCESS   :: 0
	PTHREAD_SCOPE_SYSTEM    :: 1

	pthread_t :: distinct rawptr

	pthread_attr_t :: struct {
		pta_magic:   c.uint,
		pta_flags:   c.int,
		pta_private: rawptr,
	}

	pthread_key_t :: distinct c.int

	sched_param :: struct {
		sched_priority: c.int,     /* [PSX] process or thread execution scheduling priority */
	}

} else when ODIN_OS == .OpenBSD {

	PTHREAD_CANCEL_ASYNCHRONOUS :: 2
	PTHREAD_CANCEL_DEFERRED     :: 0

	PTHREAD_CANCEL_DISABLE      :: 1
	PTHREAD_CANCEL_ENABLE       :: 0

	PTHREAD_CANCELED :: rawptr(uintptr(1))

	PTHREAD_CREATE_DETACHED :: 0x1
	PTHREAD_CREATE_JOINABLE :: 0

	PTHREAD_EXPLICIT_SCHED :: 0
	PTHREAD_INHERIT_SCHED  :: 0x4

	PTHREAD_PRIO_INHERIT :: 1
	PTHREAD_PRIO_NONE    :: 0
	PTHREAD_PRIO_PROTECT :: 2

	PTHREAD_PROCESS_SHARED  :: 0
	PTHREAD_PROCESS_PRIVATE :: 1

	PTHREAD_SCOPE_PROCESS   :: 0
	PTHREAD_SCOPE_SYSTEM    :: 0x2

	pthread_t      :: distinct rawptr
	pthread_attr_t :: distinct rawptr
	pthread_key_t  :: distinct c.int

	sched_param :: struct {
		sched_priority: c.int,     /* [PSX] process or thread execution scheduling priority */
	}

} else when ODIN_OS == .Linux {

	PTHREAD_CANCEL_DEFERRED     :: 0
	PTHREAD_CANCEL_ASYNCHRONOUS :: 1

	PTHREAD_CANCEL_ENABLE       :: 0
	PTHREAD_CANCEL_DISABLE      :: 1

	PTHREAD_CANCELED :: rawptr(~uintptr(0))

	PTHREAD_CREATE_JOINABLE :: 0
	PTHREAD_CREATE_DETACHED :: 1

	PTHREAD_INHERIT_SCHED  :: 0
	PTHREAD_EXPLICIT_SCHED :: 1

	PTHREAD_PRIO_NONE    :: 0
	PTHREAD_PRIO_INHERIT :: 1
	PTHREAD_PRIO_PROTECT :: 2

	PTHREAD_PROCESS_PRIVATE :: 0
	PTHREAD_PROCESS_SHARED  :: 1

	PTHREAD_SCOPE_SYSTEM    :: 0
	PTHREAD_SCOPE_PROCESS   :: 1

	pthread_t :: distinct c.ulong

	pthread_attr_t :: struct #raw_union {
		__size: [56]c.char, // NOTE: may be smaller depending on libc or arch, but never larger.
		__align: c.long,
	}

	pthread_key_t :: distinct c.uint

	sched_param :: struct {
		sched_priority: c.int,     /* [PSX] process or thread execution scheduling priority */

		// NOTE: may be smaller depending on libc or arch, but never larger.
		__reserved1: c.int,
		__reserved2: [4]c.long,
		__reserved3: c.int,
	}

} else {
	#panic("posix is unimplemented for the current target")
}
