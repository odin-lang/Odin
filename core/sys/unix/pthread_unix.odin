package unix;

foreign import "system:pthread"

import "core:c"
import "core:time"

//
// On success, these functions return 0.
//

@(default_calling_convention="c")
foreign pthread {
	pthread_create :: proc(t: ^pthread_t, attrs: ^pthread_attr_t, routine: proc(data: rawptr) -> rawptr, arg: rawptr) -> c.int ---;

	// retval is a pointer to a location to put the return value of the thread proc.
	pthread_join :: proc(t: pthread_t, retval: rawptr) -> c.int ---;

	pthread_self :: proc() -> pthread_t ---;

	pthread_equal :: proc(a, b: pthread_t) -> b32 ---;

	sched_get_priority_min :: proc(policy: c.int) -> c.int ---;
	sched_get_priority_max :: proc(policy: c.int) -> c.int ---;

	// NOTE: POSIX says this can fail with OOM.
	pthread_attr_init :: proc(attrs: ^pthread_attr_t) -> c.int ---;

	pthread_attr_destroy :: proc(attrs: ^pthread_attr_t) -> c.int ---;

	pthread_attr_getschedparam :: proc(attrs: ^pthread_attr_t, param: ^sched_param) -> c.int ---;
	pthread_attr_setschedparam :: proc(attrs: ^pthread_attr_t, param: ^sched_param) -> c.int ---;

	pthread_attr_getschedpolicy :: proc(t: ^pthread_attr_t, policy: ^c.int) -> c.int ---;
	pthread_attr_setschedpolicy :: proc(t: ^pthread_attr_t, policy: c.int) -> c.int ---;

	// states: PTHREAD_CREATE_DETACHED, PTHREAD_CREATE_JOINABLE
	pthread_attr_setdetachstate :: proc(attrs: ^pthread_attr_t, detach_state: c.int) -> c.int ---;

	// scheds: PTHREAD_INHERIT_SCHED, PTHREAD_EXPLICIT_SCHED
	pthread_attr_setinheritsched :: proc(attrs: ^pthread_attr_t, sched: c.int) -> c.int ---;

	// NOTE(tetra, 2019-11-06): WARNING: Different systems have different alignment requirements.
	// For maximum usefulness, use the OS's page size.
	// ALSO VERY MAJOR WARNING: `stack_ptr` must be the LAST byte of the stack on systems
	// where the stack grows downwards, which is the common case, so far as I know.
	// On systems where it grows upwards, give the FIRST byte instead.
	// ALSO SLIGHTLY LESS MAJOR WARNING: Using this procedure DISABLES automatically-provided
	// guard pages. If you are using this procedure, YOU must set them up manually.
	// If you forget to do this, you WILL get stack corruption bugs if you do not EXTREMELY
	// know what you are doing!
	pthread_attr_setstack :: proc(attrs: ^pthread_attr_t, stack_ptr: rawptr, stack_size: u64) -> c.int ---;
	pthread_attr_getstack :: proc(attrs: ^pthread_attr_t, stack_ptr: ^rawptr, stack_size: ^u64) -> c.int ---;
}

@(default_calling_convention="c")
foreign pthread {
	// NOTE: POSIX says this can fail with OOM.
	pthread_cond_init :: proc(cond: ^pthread_cond_t, attrs: ^pthread_condattr_t) -> c.int ---;

	pthread_cond_destroy :: proc(cond: ^pthread_cond_t) -> c.int ---;

	pthread_cond_signal :: proc(cond: ^pthread_cond_t) -> c.int ---;

	// same as signal, but wakes up _all_ threads that are waiting
	pthread_cond_broadcast :: proc(cond: ^pthread_cond_t) -> c.int ---;


	// assumes the mutex is pre-locked
	pthread_cond_wait :: proc(cond: ^pthread_cond_t, mutex: ^pthread_mutex_t) -> c.int ---;
	pthread_cond_timedwait :: proc(cond: ^pthread_cond_t, mutex: ^pthread_mutex_t, timeout: ^time.TimeSpec) -> c.int ---;

	pthread_condattr_init :: proc(attrs: ^pthread_condattr_t) -> c.int ---;
	pthread_condattr_destroy :: proc(attrs: ^pthread_condattr_t) -> c.int ---;

	// p-shared = "process-shared" - i.e: is this condition shared among multiple processes?
	// values: PTHREAD_PROCESS_PRIVATE, PTHREAD_PROCESS_SHARED
	pthread_condattr_setpshared :: proc(attrs: ^pthread_condattr_t, value: c.int) -> c.int ---;
	pthread_condattr_getpshared :: proc(attrs: ^pthread_condattr_t, result: ^c.int) -> c.int ---;

}

@(default_calling_convention="c")
foreign pthread {
	// NOTE: POSIX says this can fail with OOM.
	pthread_mutex_init :: proc(mutex: ^pthread_mutex_t, attrs: ^pthread_mutexattr_t) -> c.int ---;

	pthread_mutex_destroy :: proc(mutex: ^pthread_mutex_t) -> c.int ---;

	pthread_mutex_trylock :: proc(mutex: ^pthread_mutex_t) -> c.int ---;

	pthread_mutex_lock :: proc(mutex: ^pthread_mutex_t) -> c.int ---;

	pthread_mutex_timedlock :: proc(mutex: ^pthread_mutex_t, timeout: ^time.TimeSpec) -> c.int ---;

	pthread_mutex_unlock :: proc(mutex: ^pthread_mutex_t) -> c.int ---;


	pthread_mutexattr_init :: proc(attrs: ^pthread_mutexattr_t) -> c.int ---;
	pthread_mutexattr_destroy :: proc(attrs: ^pthread_mutexattr_t) -> c.int ---;

	// p-shared = "process-shared" - i.e: is this mutex shared among multiple processes?
	// values: PTHREAD_PROCESS_PRIVATE, PTHREAD_PROCESS_SHARED
	pthread_mutexattr_setpshared :: proc(attrs: ^pthread_mutexattr_t, value: c.int) -> c.int ---;
	pthread_mutexattr_getpshared :: proc(attrs: ^pthread_mutexattr_t, result: ^c.int) -> c.int ---;

}