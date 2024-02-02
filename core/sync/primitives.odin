package sync

import "base:runtime"
import "core:time"

current_thread_id :: proc "contextless" () -> int {
	return _current_thread_id()
}

// A Mutex is a [[mutual exclusion lock; https://en.wikipedia.org/wiki/Mutual_exclusion]]
// It can be used to prevent more than one thread from executing the same piece of code,
// and thus prevent access to same piece of memory by multiple threads, at the same time.
//
// A Mutex's zero value represents an initial, *unlocked* state.
//
// If another thread tries to take the lock while another thread holds it, it will pause
// until the lock is released. Code or memory that is "surrounded" by a mutex lock is said
// to be "guarded by a mutex".
//
// A Mutex must not be copied after first use (e.g., after locking it the first time).
// This is because, in order to coordinate with other threads, all threads must watch
// the same memory address to know when the lock has been released. Trying to use a
// copy of the lock at a different memory address will result in broken and unsafe
// behavior. For this reason, Mutexes are marked as `#no_copy`.
Mutex :: struct #no_copy {
	impl: _Mutex,
}

// mutex_lock locks m
mutex_lock :: proc "contextless" (m: ^Mutex) {
	_mutex_lock(m)
}

// mutex_unlock unlocks m
mutex_unlock :: proc "contextless" (m: ^Mutex) {
	_mutex_unlock(m)
}

// mutex_try_lock tries to lock m, will return true on success, and false on failure
mutex_try_lock :: proc "contextless" (m: ^Mutex) -> bool {
	return _mutex_try_lock(m)
}

/*
Example:
	if mutex_guard(&m) {
		...
	}
*/
@(deferred_in=mutex_unlock)
mutex_guard :: proc "contextless" (m: ^Mutex) -> bool {
	mutex_lock(m)
	return true
}

// A RW_Mutex is a reader/writer mutual exclusion lock
// The lock can be held by any arbitrary number of readers or a single writer
// The zero value for a RW_Mutex is an unlocked mutex
//
// A RW_Mutex must not be copied after first use
RW_Mutex :: struct #no_copy {
	impl: _RW_Mutex,
}

// rw_mutex_lock locks rw for writing (with a single writer)
// If the mutex is already locked for reading or writing, the mutex blocks until the mutex is available.
rw_mutex_lock :: proc "contextless" (rw: ^RW_Mutex) {
	_rw_mutex_lock(rw)
}

// rw_mutex_unlock unlocks rw for writing (with a single writer)
rw_mutex_unlock :: proc "contextless" (rw: ^RW_Mutex) {
	_rw_mutex_unlock(rw)
}

// rw_mutex_try_lock tries to lock rw for writing (with a single writer)
rw_mutex_try_lock :: proc "contextless" (rw: ^RW_Mutex) -> bool {
	return _rw_mutex_try_lock(rw)
}

// rw_mutex_shared_lock locks rw for reading (with arbitrary number of readers)
rw_mutex_shared_lock :: proc "contextless" (rw: ^RW_Mutex) {
	_rw_mutex_shared_lock(rw)
}

// rw_mutex_shared_unlock unlocks rw for reading (with arbitrary number of readers)
rw_mutex_shared_unlock :: proc "contextless" (rw: ^RW_Mutex) {
	_rw_mutex_shared_unlock(rw)
}

// rw_mutex_try_shared_lock tries to lock rw for reading (with arbitrary number of readers)
rw_mutex_try_shared_lock :: proc "contextless" (rw: ^RW_Mutex) -> bool {
	return _rw_mutex_try_shared_lock(rw)
}
/*
Example:
	if rw_mutex_guard(&m) {
		...
	}
*/
@(deferred_in=rw_mutex_unlock)
rw_mutex_guard :: proc "contextless" (m: ^RW_Mutex) -> bool {
	rw_mutex_lock(m)
	return true
}

/*
Example:
	if rw_mutex_shared_guard(&m) {
		...
	}
*/
@(deferred_in=rw_mutex_shared_unlock)
rw_mutex_shared_guard :: proc "contextless" (m: ^RW_Mutex) -> bool {
	rw_mutex_shared_lock(m)
	return true
}



// A Recursive_Mutex is a recursive mutual exclusion lock
// The zero value for a Recursive_Mutex is an unlocked mutex
//
// A Recursive_Mutex must not be copied after first use
Recursive_Mutex :: struct #no_copy {
	impl: _Recursive_Mutex,
}

recursive_mutex_lock :: proc "contextless" (m: ^Recursive_Mutex) {
	_recursive_mutex_lock(m)
}

recursive_mutex_unlock :: proc "contextless" (m: ^Recursive_Mutex) {
	_recursive_mutex_unlock(m)
}

recursive_mutex_try_lock :: proc "contextless" (m: ^Recursive_Mutex) -> bool {
	return _recursive_mutex_try_lock(m)
}

/*
Example:
	if recursive_mutex_guard(&m) {
		...
	}
*/
@(deferred_in=recursive_mutex_unlock)
recursive_mutex_guard :: proc "contextless" (m: ^Recursive_Mutex) -> bool {
	recursive_mutex_lock(m)
	return true
}


// Cond implements a condition variable, a rendezvous point for threads
// waiting for signalling the occurence of an event
//
// A Cond must not be copied after first use
Cond :: struct #no_copy {
	impl: _Cond,
}

cond_wait :: proc "contextless" (c: ^Cond, m: ^Mutex) {
	_cond_wait(c, m)
}

cond_wait_with_timeout :: proc "contextless" (c: ^Cond, m: ^Mutex, duration: time.Duration) -> bool {
	if duration <= 0 {
		return false
	}
	return _cond_wait_with_timeout(c, m, duration)
}

cond_signal :: proc "contextless" (c: ^Cond) {
	_cond_signal(c)
}

cond_broadcast :: proc "contextless" (c: ^Cond) {
	_cond_broadcast(c)
}


// When waited upon, blocks until the internal count is greater than zero, then subtracts one.
// Posting to the semaphore increases the count by one, or the provided amount.
//
// A Sema must not be copied after first use
Sema :: struct #no_copy {
	impl: _Sema,
}

sema_post :: proc "contextless" (s: ^Sema, count := 1) {
	_sema_post(s, count)
}

sema_wait :: proc "contextless" (s: ^Sema) {
	_sema_wait(s)
}

sema_wait_with_timeout :: proc "contextless" (s: ^Sema, duration: time.Duration) -> bool {
	return _sema_wait_with_timeout(s, duration)
}



// Futex is a fast userspace mutual exclusion lock, using a 32-bit memory address as a hint
// 
// An Futex must not be copied after first use
Futex :: distinct u32

futex_wait :: proc "contextless" (f: ^Futex, expected: u32) {
	if u32(atomic_load_explicit(f, .Acquire)) != expected {
		return
	}
	
	_assert(_futex_wait(f, expected), "futex_wait failure")
}

// returns true if the wait happened within the duration, false if it exceeded the time duration
futex_wait_with_timeout :: proc "contextless" (f: ^Futex, expected: u32, duration: time.Duration) -> bool {
	if u32(atomic_load_explicit(f, .Acquire)) != expected {
		return true
	}
	if duration <= 0 {
		return false
	}	
	
	return _futex_wait_with_timeout(f, expected, duration)
}

futex_signal :: proc "contextless" (f: ^Futex) {
	_futex_signal(f)
}

futex_broadcast :: proc "contextless" (f: ^Futex) {
	_futex_broadcast(f)
}


@(private)
_assert :: proc "contextless" (cond: bool, msg: string) {
	if !cond {
		_panic(msg)
	}
}

@(private)
_panic :: proc "contextless" (msg: string) -> ! {
	runtime.print_string(msg)
	runtime.print_byte('\n')
	runtime.trap()
}
