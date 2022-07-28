//+private
package sync

import "core:time"

_Sema :: struct {
	atomic: Atomic_Sema,
}

_sema_post :: proc(s: ^Sema, count := 1) {
	atomic_sema_post(&s.impl.atomic, count)
}

_sema_wait :: proc(s: ^Sema) {
	atomic_sema_wait(&s.impl.atomic)
}

_sema_wait_with_timeout :: proc(s: ^Sema, duration: time.Duration) -> bool {
	return atomic_sema_wait_with_timeout(&s.impl.atomic, duration)
}


_Recursive_Mutex :: struct {
	owner:     Futex,
	recursion: i32,
}

_recursive_mutex_lock :: proc(m: ^Recursive_Mutex) {
	tid := Futex(current_thread_id())
	for {
		prev_owner := atomic_compare_exchange_strong_explicit(&m.impl.owner, 0, tid, .Acquire, .Acquire)
		switch prev_owner {
		case 0, tid:
			m.impl.recursion += 1
			// inside the lock
			return
		}

		futex_wait(&m.impl.owner, u32(prev_owner))
	}
}

_recursive_mutex_unlock :: proc(m: ^Recursive_Mutex) {
	m.impl.recursion -= 1
	if m.impl.recursion != 0 {
		return
	}
	atomic_exchange_explicit(&m.impl.owner, 0, .Release)

	futex_signal(&m.impl.owner)
	// outside the lock

}

_recursive_mutex_try_lock :: proc(m: ^Recursive_Mutex) -> bool {
	tid := Futex(current_thread_id())
	prev_owner := atomic_compare_exchange_strong_explicit(&m.impl.owner, 0, tid, .Acquire, .Acquire)
	switch prev_owner {
	case 0, tid:
		m.impl.recursion += 1
		// inside the lock
		return true
	}
	return false
}


when ODIN_OS != .Windows {
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


	_RW_Mutex :: struct {
		mutex: Atomic_RW_Mutex,
	}

	_rw_mutex_lock :: proc(rw: ^RW_Mutex) {
		atomic_rw_mutex_lock(&rw.impl.mutex)
	}

	_rw_mutex_unlock :: proc(rw: ^RW_Mutex) {
		atomic_rw_mutex_unlock(&rw.impl.mutex)
	}

	_rw_mutex_try_lock :: proc(rw: ^RW_Mutex) -> bool {
		return atomic_rw_mutex_try_lock(&rw.impl.mutex)
	}

	_rw_mutex_shared_lock :: proc(rw: ^RW_Mutex) {
		atomic_rw_mutex_shared_lock(&rw.impl.mutex)
	}

	_rw_mutex_shared_unlock :: proc(rw: ^RW_Mutex) {
		atomic_rw_mutex_shared_unlock(&rw.impl.mutex)
	}

	_rw_mutex_try_shared_lock :: proc(rw: ^RW_Mutex) -> bool {
		return atomic_rw_mutex_try_shared_lock(&rw.impl.mutex)
	}
}