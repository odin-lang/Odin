//+private
package sync

when #config(ODIN_SYNC_RECURSIVE_MUTEX_USE_FUTEX, true) {
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
} else {
	_Recursive_Mutex :: struct {
		owner:     int,
		recursion: int,
		mutex:     Mutex,
	}

	_recursive_mutex_lock :: proc(m: ^Recursive_Mutex) {
		tid := current_thread_id()
		if tid != m.impl.owner {
			mutex_lock(&m.impl.mutex)
		}
		// inside the lock
		m.impl.owner = tid
		m.impl.recursion += 1
	}

	_recursive_mutex_unlock :: proc(m: ^Recursive_Mutex) {
		tid := current_thread_id()
		assert(tid == m.impl.owner)
		m.impl.recursion -= 1
		recursion := m.impl.recursion
		if recursion == 0 {
			m.impl.owner = 0
		}
		if recursion == 0 {
			mutex_unlock(&m.impl.mutex)
		}
		// outside the lock

	}

	_recursive_mutex_try_lock :: proc(m: ^Recursive_Mutex) -> bool {
		tid := current_thread_id()
		if m.impl.owner == tid {
			return mutex_try_lock(&m.impl.mutex)
		}
		if !mutex_try_lock(&m.impl.mutex) {
			return false
		}
		// inside the lock
		m.impl.owner = tid
		m.impl.recursion += 1
		return true
	}
}


when ODIN_OS != .Windows {
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