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
			prev_owner := atomic_compare_exchange_strong_explicit(&m.impl.owner, tid, 0, .acquire, .acquire)
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
		atomic_exchange_explicit(&m.impl.owner, 0, .release)
		
		futex_signal(&m.impl.owner)
		// outside the lock

	}

	_recursive_mutex_try_lock :: proc(m: ^Recursive_Mutex) -> bool {
		tid := Futex(current_thread_id())
		prev_owner := atomic_compare_exchange_strong_explicit(&m.impl.owner, tid, 0, .acquire, .acquire)
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
	RW_Mutex_State :: distinct uint
	RW_Mutex_State_Half_Width :: size_of(RW_Mutex_State)*8/2
	RW_Mutex_State_Is_Writing :: RW_Mutex_State(1)
	RW_Mutex_State_Writer     :: RW_Mutex_State(1)<<1
	RW_Mutex_State_Reader     :: RW_Mutex_State(1)<<RW_Mutex_State_Half_Width

	RW_Mutex_State_Writer_Mask :: RW_Mutex_State(1<<(RW_Mutex_State_Half_Width-1) - 1) << 1
	RW_Mutex_State_Reader_Mask :: RW_Mutex_State(1<<(RW_Mutex_State_Half_Width-1) - 1) << RW_Mutex_State_Half_Width


	_RW_Mutex :: struct {
		// NOTE(bill): pthread_rwlock_t cannot be used since pthread_rwlock_destroy is required on some platforms
		// TODO(bill): Can we determine which platforms exactly?
		state: RW_Mutex_State,
		mutex: Mutex,
		sema:  Sema,
	}

	_rw_mutex_lock :: proc(rw: ^RW_Mutex) {
		_ = atomic_add(&rw.impl.state, RW_Mutex_State_Writer)
		mutex_lock(&rw.impl.mutex)

		state := atomic_or(&rw.impl.state, RW_Mutex_State_Writer)
		if state & RW_Mutex_State_Reader_Mask != 0 {
			sema_wait(&rw.impl.sema)
		}
	}

	_rw_mutex_unlock :: proc(rw: ^RW_Mutex) {
		_ = atomic_and(&rw.impl.state, ~RW_Mutex_State_Is_Writing)
		mutex_unlock(&rw.impl.mutex)
	}

	_rw_mutex_try_lock :: proc(rw: ^RW_Mutex) -> bool {
		if mutex_try_lock(&rw.impl.mutex) {
			state := atomic_load(&rw.impl.state)
			if state & RW_Mutex_State_Reader_Mask == 0 {
				_ = atomic_or(&rw.impl.state, RW_Mutex_State_Is_Writing)
				return true
			}

			mutex_unlock(&rw.impl.mutex)
		}
		return false
	}

	_rw_mutex_shared_lock :: proc(rw: ^RW_Mutex) {
		state := atomic_load(&rw.impl.state)
		for state & (RW_Mutex_State_Is_Writing|RW_Mutex_State_Writer_Mask) == 0 {
			ok: bool
			state, ok = atomic_compare_exchange_weak(&rw.impl.state, state, state + RW_Mutex_State_Reader)
			if ok {
				return
			}
		}

		mutex_lock(&rw.impl.mutex)
		_ = atomic_add(&rw.impl.state, RW_Mutex_State_Reader)
		mutex_unlock(&rw.impl.mutex)
	}

	_rw_mutex_shared_unlock :: proc(rw: ^RW_Mutex) {
		state := atomic_sub(&rw.impl.state, RW_Mutex_State_Reader)

		if (state & RW_Mutex_State_Reader_Mask == RW_Mutex_State_Reader) &&
		   (state & RW_Mutex_State_Is_Writing != 0) {
		   	sema_post(&rw.impl.sema)
		}
	}

	_rw_mutex_try_shared_lock :: proc(rw: ^RW_Mutex) -> bool {
		state := atomic_load(&rw.impl.state)
		if state & (RW_Mutex_State_Is_Writing|RW_Mutex_State_Writer_Mask) == 0 {
			_, ok := atomic_compare_exchange_strong(&rw.impl.state, state, state + RW_Mutex_State_Reader)
			if ok {
				return true
			}
		}
		if mutex_try_lock(&rw.impl.mutex) {
			_ = atomic_add(&rw.impl.state, RW_Mutex_State_Reader)
			mutex_unlock(&rw.impl.mutex)
			return true
		}

		return false
	}

}