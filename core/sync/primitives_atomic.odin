package sync

import "core:time"

Atomic_Mutex_State :: enum Futex {
	Unlocked = 0,
	Locked   = 1,
	Waiting  = 2,
}


// An Atomic_Mutex is a mutual exclusion lock
// The zero value for a Atomic_Mutex is an unlocked mutex
//
// An Atomic_Mutex must not be copied after first use
Atomic_Mutex :: struct #no_copy {
	state: Atomic_Mutex_State,
}

// atomic_mutex_lock locks m
atomic_mutex_lock :: proc "contextless" (m: ^Atomic_Mutex) {
	@(cold)
	lock_slow :: proc "contextless" (m: ^Atomic_Mutex, curr_state: Atomic_Mutex_State) {
		new_state := curr_state // Make a copy of it

		spin_lock: for spin in 0..<i32(100) {
			state, ok := atomic_compare_exchange_weak_explicit(&m.state, .Unlocked, new_state, .Acquire, .Consume)
			if ok {
				return
			}

			if state == .Waiting {
				break spin_lock
			}

			for i := min(spin+1, 32); i > 0; i -= 1 {
				cpu_relax()
			}
		}

		// Set just in case 100 iterations did not do it
		new_state = .Waiting

		for {
			if atomic_exchange_explicit(&m.state, .Waiting, .Acquire) == .Unlocked {
				return
			}
			
			futex_wait((^Futex)(&m.state), u32(new_state))
			cpu_relax()
		}
	}


	if v := atomic_exchange_explicit(&m.state, .Locked, .Acquire); v != .Unlocked {
		lock_slow(m, v)
	}
}

// atomic_mutex_unlock unlocks m
atomic_mutex_unlock :: proc "contextless" (m: ^Atomic_Mutex) {
	@(cold)
	unlock_slow :: proc "contextless" (m: ^Atomic_Mutex) {
		futex_signal((^Futex)(&m.state))
	}


	switch atomic_exchange_explicit(&m.state, .Unlocked, .Release) {
	case .Unlocked:
		// Kind of okay - unlocking while already unlocked.
	case .Locked:
		// Okay
	case .Waiting:
		unlock_slow(m)
	}
}

// atomic_mutex_try_lock tries to lock m, will return true on success, and false on failure
atomic_mutex_try_lock :: proc "contextless" (m: ^Atomic_Mutex) -> bool {
	_, ok := atomic_compare_exchange_strong_explicit(&m.state, .Unlocked, .Locked, .Acquire, .Consume)
	return ok
}

/*
Example:
	if atomic_mutex_guard(&m) {
		...
	}
*/
@(deferred_in=atomic_mutex_unlock)
atomic_mutex_guard :: proc "contextless" (m: ^Atomic_Mutex) -> bool {
	atomic_mutex_lock(m)
	return true
}


Atomic_RW_Mutex_State :: distinct uint
Atomic_RW_Mutex_State_Half_Width :: size_of(Atomic_RW_Mutex_State)*8/2
Atomic_RW_Mutex_State_Is_Writing :: Atomic_RW_Mutex_State(1)
Atomic_RW_Mutex_State_Writer     :: Atomic_RW_Mutex_State(1)<<1
Atomic_RW_Mutex_State_Reader     :: Atomic_RW_Mutex_State(1)<<Atomic_RW_Mutex_State_Half_Width

Atomic_RW_Mutex_State_Writer_Mask :: Atomic_RW_Mutex_State(1<<(Atomic_RW_Mutex_State_Half_Width-1) - 1) << 1
Atomic_RW_Mutex_State_Reader_Mask :: Atomic_RW_Mutex_State(1<<(Atomic_RW_Mutex_State_Half_Width-1) - 1) << Atomic_RW_Mutex_State_Half_Width


// An Atomic_RW_Mutex is a reader/writer mutual exclusion lock
// The lock can be held by any arbitrary number of readers or a single writer
// The zero value for an Atomic_RW_Mutex is an unlocked mutex
//
// An Atomic_RW_Mutex must not be copied after first use
Atomic_RW_Mutex :: struct #no_copy {
	state: Atomic_RW_Mutex_State,
	mutex: Atomic_Mutex,
	sema:  Atomic_Sema,
}

// atomic_rw_mutex_lock locks rw for writing (with a single writer)
// If the mutex is already locked for reading or writing, the mutex blocks until the mutex is available.
atomic_rw_mutex_lock :: proc "contextless" (rw: ^Atomic_RW_Mutex) {
	_ = atomic_add(&rw.state, Atomic_RW_Mutex_State_Writer)
	atomic_mutex_lock(&rw.mutex)

	state := atomic_or(&rw.state, Atomic_RW_Mutex_State_Writer)
	if state & Atomic_RW_Mutex_State_Reader_Mask != 0 {
		atomic_sema_wait(&rw.sema)
	}
}

// atomic_rw_mutex_unlock unlocks rw for writing (with a single writer)
atomic_rw_mutex_unlock :: proc "contextless" (rw: ^Atomic_RW_Mutex) {
	_ = atomic_and(&rw.state, ~Atomic_RW_Mutex_State_Is_Writing)
	atomic_mutex_unlock(&rw.mutex)
}

// atomic_rw_mutex_try_lock tries to lock rw for writing (with a single writer)
atomic_rw_mutex_try_lock :: proc "contextless" (rw: ^Atomic_RW_Mutex) -> bool {
	if atomic_mutex_try_lock(&rw.mutex) {
		state := atomic_load(&rw.state)
		if state & Atomic_RW_Mutex_State_Reader_Mask == 0 {
			_ = atomic_or(&rw.state, Atomic_RW_Mutex_State_Is_Writing)
			return true
		}

		atomic_mutex_unlock(&rw.mutex)
	}
	return false
}

// atomic_rw_mutex_shared_lock locks rw for reading (with arbitrary number of readers)
atomic_rw_mutex_shared_lock :: proc "contextless" (rw: ^Atomic_RW_Mutex) {
	state := atomic_load(&rw.state)
	for state & (Atomic_RW_Mutex_State_Is_Writing|Atomic_RW_Mutex_State_Writer_Mask) == 0 {
		ok: bool
		state, ok = atomic_compare_exchange_weak(&rw.state, state, state + Atomic_RW_Mutex_State_Reader)
		if ok {
			return
		}
	}

	atomic_mutex_lock(&rw.mutex)
	_ = atomic_add(&rw.state, Atomic_RW_Mutex_State_Reader)
	atomic_mutex_unlock(&rw.mutex)
}

// atomic_rw_mutex_shared_unlock unlocks rw for reading (with arbitrary number of readers)
atomic_rw_mutex_shared_unlock :: proc "contextless" (rw: ^Atomic_RW_Mutex) {
	state := atomic_sub(&rw.state, Atomic_RW_Mutex_State_Reader)

	if (state & Atomic_RW_Mutex_State_Reader_Mask == Atomic_RW_Mutex_State_Reader) &&
	   (state & Atomic_RW_Mutex_State_Is_Writing != 0) {
		atomic_sema_post(&rw.sema)
	}
}

// atomic_rw_mutex_try_shared_lock tries to lock rw for reading (with arbitrary number of readers)
atomic_rw_mutex_try_shared_lock :: proc "contextless" (rw: ^Atomic_RW_Mutex) -> bool {
	state := atomic_load(&rw.state)
	if state & (Atomic_RW_Mutex_State_Is_Writing|Atomic_RW_Mutex_State_Writer_Mask) == 0 {
		_, ok := atomic_compare_exchange_strong(&rw.state, state, state + Atomic_RW_Mutex_State_Reader)
		if ok {
			return true
		}
	}
	if atomic_mutex_try_lock(&rw.mutex) {
		_ = atomic_add(&rw.state, Atomic_RW_Mutex_State_Reader)
		atomic_mutex_unlock(&rw.mutex)
		return true
	}

	return false
}

/*
Example:
	if atomic_rw_mutex_guard(&m) {
		...
	}
*/
@(deferred_in=atomic_rw_mutex_unlock)
atomic_rw_mutex_guard :: proc "contextless" (m: ^Atomic_RW_Mutex) -> bool {
	atomic_rw_mutex_lock(m)
	return true
}

/*
Example:
	if atomic_rw_mutex_shared_guard(&m) {
		...
	}
*/
@(deferred_in=atomic_rw_mutex_shared_unlock)
atomic_rw_mutex_shared_guard :: proc "contextless" (m: ^Atomic_RW_Mutex) -> bool {
	atomic_rw_mutex_shared_lock(m)
	return true
}




// An Atomic_Recursive_Mutex is a recursive mutual exclusion lock
// The zero value for a Recursive_Mutex is an unlocked mutex
//
// An Atomic_Recursive_Mutex must not be copied after first use
Atomic_Recursive_Mutex :: struct #no_copy {
	owner:     int,
	recursion: int,
	mutex: Mutex,
}

atomic_recursive_mutex_lock :: proc "contextless" (m: ^Atomic_Recursive_Mutex) {
	tid := current_thread_id()
	if tid != m.owner {
		mutex_lock(&m.mutex)
	}
	// inside the lock
	m.owner = tid
	m.recursion += 1
}

atomic_recursive_mutex_unlock :: proc "contextless" (m: ^Atomic_Recursive_Mutex) {
	tid := current_thread_id()
	assert_contextless(tid == m.owner, "tid != m.owner")
	m.recursion -= 1
	recursion := m.recursion
	if recursion == 0 {
		m.owner = 0
	}
	if recursion == 0 {
		mutex_unlock(&m.mutex)
	}
	// outside the lock

}

atomic_recursive_mutex_try_lock :: proc "contextless" (m: ^Atomic_Recursive_Mutex) -> bool {
	tid := current_thread_id()
	if m.owner == tid {
		return mutex_try_lock(&m.mutex)
	}
	if !mutex_try_lock(&m.mutex) {
		return false
	}
	// inside the lock
	m.owner = tid
	m.recursion += 1
	return true
}

/*
Example:
	if atomic_recursive_mutex_guard(&m) {
		...
	}
*/
@(deferred_in=atomic_recursive_mutex_unlock)
atomic_recursive_mutex_guard :: proc "contextless" (m: ^Atomic_Recursive_Mutex) -> bool {
	atomic_recursive_mutex_lock(m)
	return true
}



// Atomic_Cond implements a condition variable, a rendezvous point for threads
// waiting for signalling the occurence of an event
//
// An Atomic_Cond must not be copied after first use
Atomic_Cond :: struct #no_copy {
	state: Futex,
}

atomic_cond_wait :: proc "contextless" (c: ^Atomic_Cond, m: ^Atomic_Mutex) {
	state := u32(atomic_load_explicit(&c.state, .Relaxed))
	unlock(m)
	futex_wait(&c.state, state)
	lock(m)

}

atomic_cond_wait_with_timeout :: proc "contextless" (c: ^Atomic_Cond, m: ^Atomic_Mutex, duration: time.Duration) -> (ok: bool) {
	state := u32(atomic_load_explicit(&c.state, .Relaxed))
	unlock(m)
	ok = futex_wait_with_timeout(&c.state, state, duration)
	lock(m)
	return
}


atomic_cond_signal :: proc "contextless" (c: ^Atomic_Cond) {
	atomic_add_explicit(&c.state, 1, .Release)
	futex_signal(&c.state)
}

atomic_cond_broadcast :: proc "contextless" (c: ^Atomic_Cond) {
	atomic_add_explicit(&c.state, 1, .Release)
	futex_broadcast(&c.state)
}

// When waited upon, blocks until the internal count is greater than zero, then subtracts one.
// Posting to the semaphore increases the count by one, or the provided amount.
//
// An Atomic_Sema must not be copied after first use
Atomic_Sema :: struct #no_copy {
	count: Futex,
}

atomic_sema_post :: proc "contextless" (s: ^Atomic_Sema, count := 1) {
	atomic_add_explicit(&s.count, Futex(count), .Release)
	if count == 1 {
		futex_signal(&s.count)
	} else {
		futex_broadcast(&s.count)
	}
}

atomic_sema_wait :: proc "contextless" (s: ^Atomic_Sema) {
	for {
		original_count := atomic_load_explicit(&s.count, .Relaxed)
		for original_count == 0 {
			futex_wait(&s.count, u32(original_count))
			original_count = atomic_load_explicit(&s.count, .Relaxed)
		}
		if original_count == atomic_compare_exchange_strong_explicit(&s.count, original_count, original_count-1, .Acquire, .Acquire) {
			return
		}
	}
}

atomic_sema_wait_with_timeout :: proc "contextless" (s: ^Atomic_Sema, duration: time.Duration) -> bool {
	if duration <= 0 {
		return false
	}
	for {
		original_count := atomic_load_explicit(&s.count, .Relaxed)
		for start := time.tick_now(); original_count == 0; /**/ {
			remaining := duration - time.tick_since(start)
			if remaining < 0 {
				return false
			}

			if !futex_wait_with_timeout(&s.count, u32(original_count), remaining) {
				return false
			}
			original_count = atomic_load_explicit(&s.count, .Relaxed)
		}
		if original_count == atomic_compare_exchange_strong_explicit(&s.count, original_count, original_count-1, .Acquire, .Acquire) {
			return true
		}
	}
}
