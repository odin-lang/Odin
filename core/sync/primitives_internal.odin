#+private
package sync

import "core:time"
import vg "core:sys/valgrind"
_ :: vg

_Sema :: struct {
	atomic: Atomic_Sema,
}

_sema_post :: proc "contextless" (s: ^Sema, count := 1) {
	when ODIN_VALGRIND_SUPPORT {
		vg.helgrind_sem_post_pre(s)
	}
	atomic_sema_post(&s.impl.atomic, count)
}

_sema_wait :: proc "contextless" (s: ^Sema) {
	atomic_sema_wait(&s.impl.atomic)
	when ODIN_VALGRIND_SUPPORT {
		vg.helgrind_sem_wait_post(s)
	}
}

_sema_wait_with_timeout :: proc "contextless" (s: ^Sema, duration: time.Duration) -> bool {
	when ODIN_VALGRIND_SUPPORT {
		defer vg.helgrind_sem_wait_post(s)
	}
	return atomic_sema_wait_with_timeout(&s.impl.atomic, duration)
}


_Recursive_Mutex :: struct {
	owner:     Futex,
	recursion: i32,
}

_recursive_mutex_lock :: proc "contextless" (m: ^Recursive_Mutex) {
	when ODIN_VALGRIND_SUPPORT {
		vg.helgrind_mutex_lock_pre(m, false)
		defer vg.helgrind_mutex_lock_post(m)
	}

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

_recursive_mutex_unlock :: proc "contextless" (m: ^Recursive_Mutex) {
	when ODIN_VALGRIND_SUPPORT {
		vg.helgrind_mutex_unlock_pre(m)
		defer vg.helgrind_mutex_unlock_post(m)
	}

	m.impl.recursion -= 1
	if m.impl.recursion != 0 {
		return
	}
	atomic_exchange_explicit(&m.impl.owner, 0, .Release)

	futex_signal(&m.impl.owner)
	// outside the lock

}

_recursive_mutex_try_lock :: proc "contextless" (m: ^Recursive_Mutex) -> bool {
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

	_mutex_lock :: proc "contextless" (m: ^Mutex) {
		when ODIN_VALGRIND_SUPPORT {
			vg.helgrind_mutex_lock_pre(m, false)
			defer vg.helgrind_mutex_lock_post(m)
		}
		atomic_mutex_lock(&m.impl.mutex)
	}

	_mutex_unlock :: proc "contextless" (m: ^Mutex) {
		when ODIN_VALGRIND_SUPPORT {
			vg.helgrind_mutex_unlock_pre(m)
			defer vg.helgrind_mutex_unlock_post(m)
		}
		atomic_mutex_unlock(&m.impl.mutex)
	}

	_mutex_try_lock :: proc "contextless" (m: ^Mutex) -> bool {
		when ODIN_VALGRIND_SUPPORT {
			vg.helgrind_mutex_lock_pre(m, true)
			defer vg.helgrind_mutex_lock_post(m)
		}
		return atomic_mutex_try_lock(&m.impl.mutex)
	}

	_Cond :: struct {
		cond: Atomic_Cond,
	}

	_cond_wait :: proc "contextless" (c: ^Cond, m: ^Mutex) {
		when ODIN_VALGRIND_SUPPORT {
			_ = vg.helgrind_cond_wait_pre(c, m)
			defer _ = vg.helgrind_cond_wait_post(c, m)
		}
		atomic_cond_wait(&c.impl.cond, &m.impl.mutex)
	}

	_cond_wait_with_timeout :: proc "contextless" (c: ^Cond, m: ^Mutex, duration: time.Duration) -> bool {
		when ODIN_VALGRIND_SUPPORT {
			_ = vg.helgrind_cond_wait_pre(c, m)
			defer _ = vg.helgrind_cond_wait_post(c, m)
		}
		return atomic_cond_wait_with_timeout(&c.impl.cond, &m.impl.mutex, duration)
	}

	_cond_signal :: proc "contextless" (c: ^Cond) {
		when ODIN_VALGRIND_SUPPORT {
			vg.helgrind_cond_signal_pre(c)
		}
		atomic_cond_signal(&c.impl.cond)
	}

	_cond_broadcast :: proc "contextless" (c: ^Cond) {
		when ODIN_VALGRIND_SUPPORT {
			vg.helgrind_cond_broadcast_pre(c)
		}
		atomic_cond_broadcast(&c.impl.cond)
	}


	_RW_Mutex :: struct {
		mutex: Atomic_RW_Mutex,
	}

	_rw_mutex_lock :: proc "contextless" (rw: ^RW_Mutex) {
		when ODIN_VALGRIND_SUPPORT {
			vg.helgrind_rwlock_lock_pre(rw, true)
		}
		atomic_rw_mutex_lock(&rw.impl.mutex)
	}

	_rw_mutex_unlock :: proc "contextless" (rw: ^RW_Mutex) {
		atomic_rw_mutex_unlock(&rw.impl.mutex)
		when ODIN_VALGRIND_SUPPORT {
			vg.helgrind_rwlock_unlock_post(rw, true)
		}
	}

	_rw_mutex_try_lock :: proc "contextless" (rw: ^RW_Mutex) -> bool {
		return atomic_rw_mutex_try_lock(&rw.impl.mutex)
	}

	_rw_mutex_shared_lock :: proc "contextless" (rw: ^RW_Mutex) {
		when ODIN_VALGRIND_SUPPORT {
			vg.helgrind_rwlock_lock_pre(rw, false)
		}
		atomic_rw_mutex_shared_lock(&rw.impl.mutex)
	}

	_rw_mutex_shared_unlock :: proc "contextless" (rw: ^RW_Mutex) {
		atomic_rw_mutex_shared_unlock(&rw.impl.mutex)
		when ODIN_VALGRIND_SUPPORT {
			vg.helgrind_rwlock_unlock_post(rw, false)
		}
	}

	_rw_mutex_try_shared_lock :: proc "contextless" (rw: ^RW_Mutex) -> bool {
		return atomic_rw_mutex_try_shared_lock(&rw.impl.mutex)
	}
}