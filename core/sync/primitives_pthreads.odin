//+build linux, freebsd, openbsd
//+private
package sync2

import "core:time"
import "core:sys/unix"

_Mutex_State :: enum i32 {
	Unlocked = 0,
	Locked   = 1,
	Waiting  = 2,
}
_Mutex :: struct {
	pthread_mutex: unix.pthread_mutex_t,
}

_mutex_lock :: proc(m: ^Mutex) {
	err := unix.pthread_mutex_lock(&m.impl.pthread_mutex)
	assert(err == 0)
}

_mutex_unlock :: proc(m: ^Mutex) {
	err := unix.pthread_mutex_unlock(&m.impl.pthread_mutex)
	assert(err == 0)
}

_mutex_try_lock :: proc(m: ^Mutex) -> bool {
	err := unix.pthread_mutex_trylock(&m.impl.pthread_mutex)
	return err == 0
}

_Cond :: struct {
	pthread_cond: unix.pthread_cond_t,
}

_cond_wait :: proc(c: ^Cond, m: ^Mutex) {
	err := unix.pthread_cond_wait(&c.impl.pthread_cond, &m.impl.pthread_mutex)
	assert(err == 0)
}


_cond_wait_with_timeout :: proc(c: ^Cond, m: ^Mutex, duration: time.Duration) -> bool {
	tv_sec  := i64(duration/1e9)
	tv_nsec := i64(duration%1e9)
	err := unix.pthread_cond_timedwait(&c.impl.pthread_cond, &m.impl.pthread_mutex, &{tv_sec, tv_nsec})
	return err == 0
}


_cond_signal :: proc(c: ^Cond) {
	err := unix.pthread_cond_signal(&c.impl.pthread_cond)
	assert(err == 0)
}

_cond_broadcast :: proc(c: ^Cond) {
	err := unix.pthread_cond_broadcast(&c.impl.pthread_cond)
	assert(err == 0)
}
