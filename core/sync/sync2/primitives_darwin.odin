//+build darwin
//+private
package sync2

import "core:c"
import "core:time"
import "core:intrinsics"

foreign import pthread "System.framework"

_current_thread_id :: proc "contextless" () -> int {
	tid: u64
	// NOTE(Oskar): available from OSX 10.6 and iOS 3.2.
	// For older versions there is `syscall(SYS_thread_selfid)`, but not really
	// the same thing apparently.
	foreign pthread { pthread_threadid_np :: proc "c" (rawptr, ^u64) -> c.int --- }
	pthread_threadid_np(nil, &tid)
	return int(tid)
}



_Mutex :: struct {
	mutex: Atomic_Mutex,
}

_mutex_lock :: proc(m: ^Mutex) {
	atomic_mutex_lock(&m.impl.mutex)
}

_mutex_unlock :: proc(m: ^Mutex) {
	atomic_mutex_unlock(&m.impl.mutex)
}

_mutex_try_lock :: proc(m: ^Mutex) -> bool {
	return atomic_mutex_try_lock(&m.impl.mutex)
}

_Cond :: struct {
	cond: Atomic_Cond,
}

_cond_wait :: proc(c: ^Cond, m: ^Mutex) {
	atomic_cond_wait(&c.impl.cond, &m.impl.mutex)
}

_cond_wait_with_timeout :: proc(c: ^Cond, m: ^Mutex, duration: time.Duration) -> bool {
	return atomic_cond_wait_with_timeout(&c.impl.cond, &m.impl.mutex, duration)
}

_cond_signal :: proc(c: ^Cond) {
	atomic_cond_signal(&c.impl.cond)
}

_cond_broadcast :: proc(c: ^Cond) {
	atomic_cond_broadcast(&c.impl.cond)
}
