//+build openbsd
//+private
package sync

import "core:os"
import "core:time"

_current_thread_id :: proc "contextless" () -> int {
	return os.current_thread_id()
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
