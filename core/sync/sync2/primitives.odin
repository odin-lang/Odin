package sync2

import "core:time"

current_thread_id :: proc "contextless" () -> int {
	return _current_thread_id();
}

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

// mutex_unlock unlocks m
mutex_unlock :: proc(m: ^Mutex) {
	_mutex_unlock(m);
}

// mutex_lock tries to lock m, will return true on success, and false on failure
mutex_try_lock :: proc(m: ^Mutex) -> bool {
	return _mutex_try_lock(m);
}

// Example:
//
// if mutex_guard(&m) {
//         ...
// }
//
@(deferred_in=mutex_unlock)
mutex_guard :: proc(m: ^Mutex) -> bool {
	mutex_lock(m);
	return true;
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

// Example:
//
// if rw_mutex_guard(&m) {
//         ...
// }
//
@(deferred_in=rw_mutex_unlock)
rw_mutex_guard :: proc(m: ^RW_Mutex) -> bool {
	rw_mutex_lock(m);
	return true;
}

// Example:
//
// if rw_mutex_shared_guard(&m) {
//         ...
// }
//
@(deferred_in=rw_mutex_shared_unlock)
rw_mutex_shared_guard :: proc(m: ^RW_Mutex) -> bool {
	rw_mutex_shared_lock(m);
	return true;
}



// A Recursive_Mutex is a recursive mutual exclusion lock
// The zero value for a Recursive_Mutex is an unlocked mutex
//
// A Recursive_Mutex must not be copied after first use
Recursive_Mutex :: struct {
	impl: _Recursive_Mutex,
}

recursive_mutex_lock :: proc(m: ^Recursive_Mutex) {
	_recursive_mutex_lock(m);
}

recursive_mutex_unlock :: proc(m: ^Recursive_Mutex) {
	_recursive_mutex_unlock(m);
}

recursive_mutex_try_lock :: proc(m: ^Recursive_Mutex) -> bool {
	return _recursive_mutex_try_lock(m);
}


// Example:
//
// if recursive_mutex_guard(&m) {
//         ...
// }
//
@(deferred_in=recursive_mutex_unlock)
recursive_mutex_guard :: proc(m: ^Recursive_Mutex) -> bool {
	recursive_mutex_lock(m);
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
	impl: _Sema,
}


sema_wait :: proc(s: ^Sema) {
	_sema_wait(s);
}

sema_post :: proc(s: ^Sema, count := 1) {
	_sema_post(s, count);
}
