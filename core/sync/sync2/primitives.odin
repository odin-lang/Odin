package sync2

import "core:time"
import "core:runtime"

// A Mutex is a mutual exclusion lock
// The zero value for a Mutex is an unlocked mutex
//
// A Mutex must not be copied after first use
Mutex :: struct {
	impl: _Mutex,
}

// mutex_lock locks m
mutex_lock :: proc(m: ^Mutex) {
	_mutex_lock(m);
}

// mutex_lock unlocks m
mutex_unlock :: proc(m: ^Mutex) {
	_mutex_unlock(m);
}

// mutex_lock tries to lock m, will return true on success, and false on failure
mutex_try_lock :: proc(m: ^Mutex) -> bool {
	return _mutex_try_lock(m);
}

// A RW_Mutex is a reader/writer mutual exclusion lock
// The lock can be held by any arbitrary number of readers or a single writer
// The zero value for a RW_Mutex is an unlocked mutex
//
// A RW_Mutex must not be copied after first use
RW_Mutex :: struct {
	impl: _RW_Mutex,
}

// rw_mutex_lock locks rw for writing (with a single writer)
// If the mutex is already locked for reading or writing, the mutex blocks until the mutex is available.
rw_mutex_lock :: proc(rw: ^RW_Mutex) {
	_rw_mutex_lock(rw);
}

// rw_mutex_unlock unlocks rw for writing (with a single writer)
rw_mutex_unlock :: proc(rw: ^RW_Mutex) {
	_rw_mutex_unlock(rw);
}

// rw_mutex_try_lock tries to lock rw for writing (with a single writer)
rw_mutex_try_lock :: proc(rw: ^RW_Mutex) -> bool {
	return _rw_mutex_try_lock(rw);
}

// rw_mutex_shared_lock locks rw for reading (with arbitrary number of readers)
rw_mutex_shared_lock :: proc(rw: ^RW_Mutex) {
	_rw_mutex_shared_lock(rw);
}

// rw_mutex_shared_unlock unlocks rw for reading (with arbitrary number of readers)
rw_mutex_shared_unlock :: proc(rw: ^RW_Mutex) {
	_rw_mutex_shared_unlock(rw);
}

// rw_mutex_try_shared_lock tries to lock rw for reading (with arbitrary number of readers)
rw_mutex_try_shared_lock :: proc(rw: ^RW_Mutex) -> bool {
	return _rw_mutex_try_shared_lock(rw);
}


// A Recusrive_Mutex is a recursive mutual exclusion lock
// The zero value for a Recursive_Mutex is an unlocked mutex
//
// A Recursive_Mutex must not be copied after first use
Recursive_Mutex :: struct {
	// TODO(bill): Is this implementation too lazy?
	// Can this be made to work on all OSes without construction and destruction, i.e. Zero is Initialized
	// CRITICAL_SECTION would be a perfect candidate for this on Windows but that cannot be "dumb"

	owner:     int,
	recursion: int,
	mutex: Mutex,
}

recursive_mutex_lock :: proc(m: ^Recursive_Mutex) {
	tid := runtime.current_thread_id();
	if tid != m.owner {
		mutex_lock(&m.mutex);
	}
	// inside the lock
	m.owner = tid;
	m.recursion += 1;
}

recursive_mutex_unlock :: proc(m: ^Recursive_Mutex) {
	tid := runtime.current_thread_id();
	assert(tid == m.owner);
	m.recursion -= 1;
	recursion := m.recursion;
	if recursion == 0 {
		m.owner = 0;
	}
	if recursion == 0 {
		mutex_unlock(&m.mutex);
	}
	// outside the lock

}

recursive_mutex_try_lock :: proc(m: ^Recursive_Mutex) -> bool {
	tid := runtime.current_thread_id();
	if m.owner == tid {
		return mutex_try_lock(&m.mutex);
	}
	if !mutex_try_lock(&m.mutex) {
		return false;
	}
	// inside the lock
	m.owner = tid;
	m.recursion += 1;
	return true;
}



// Cond implements a condition variable, a rendezvous point for threads
// waiting for signalling the occurence of an event
//
// A Cond must not be copied after first use
Cond :: struct {
	impl: _Cond,
}

cond_wait :: proc(c: ^Cond, m: ^Mutex) {
	_cond_wait(c, m);
}

cond_wait_with_timeout :: proc(c: ^Cond, m: ^Mutex, timeout: time.Duration) -> bool {
	return _cond_wait_with_timeout(c, m, timeout);
}

cond_signal :: proc(c: ^Cond) {
	_cond_signal(c);
}

cond_broadcast :: proc(c: ^Cond) {
	_cond_broadcast(c);
}



// When waited upon, blocks until the internal count is greater than zero, then subtracts one.
// Posting to the semaphore increases the count by one, or the provided amount.
//
// A Sema must not be copied after first use
Sema :: struct {
	// TODO(bill): Is this implementation too lazy?
	// Can this be made to work on all OSes without construction and destruction, i.e. Zero is Initialized

	mutex: Mutex,
	cond:  Cond,
	count: int,
}


sema_wait :: proc(s: ^Sema) {
	mutex_lock(&s.mutex);
	defer mutex_unlock(&s.mutex);

	for s.count == 0 {
		cond_wait(&s.cond, &s.mutex);
	}

	s.count -= 1;
	if s.count > 0 {
		cond_signal(&s.cond);
	}
}

sema_post :: proc(s: ^Sema, count := 1) {
	mutex_lock(&s.mutex);
	defer mutex_unlock(&s.mutex);

	s.count += count;
	cond_signal(&s.cond);
}
