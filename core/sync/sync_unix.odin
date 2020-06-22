// +build linux, darwin
package sync

import "core:sys/unix"

// A lock that can only be held by one thread at once.
Mutex :: struct {
	handle: unix.pthread_mutex_t,
}

// Blocks until signalled, and then lets past exactly
// one thread.
Condition :: struct {
	handle: unix.pthread_cond_t,
	mutex:  ^Mutex,

	// NOTE(tetra, 2019-11-11): Used to mimic the more sane behavior of Windows' AutoResetEvent.
	// This means that you may signal the condition before anyone is waiting to cause the
	// next thread that tries to wait to just pass by uninterrupted, without sleeping.
	// Without this, signalling a condition will only wake up a thread which is already waiting,
	// but not one that is about to wait, which can cause your program to become out of sync in
	// ways that are hard to debug or fix.
	flag: bool, // atomically mutated
}



mutex_init :: proc(m: ^Mutex) {
	// NOTE(tetra, 2019-11-01): POSIX OOM if we cannot init the attrs or the mutex.
	attrs: unix.pthread_mutexattr_t;
	assert(unix.pthread_mutexattr_init(&attrs) == 0);
	defer unix.pthread_mutexattr_destroy(&attrs); // ignores destruction error

	assert(unix.pthread_mutex_init(&m.handle, &attrs) == 0);
}

mutex_destroy :: proc(m: ^Mutex) {
	assert(unix.pthread_mutex_destroy(&m.handle) == 0);
	m.handle = {};
}

mutex_lock :: proc(m: ^Mutex) {
	assert(unix.pthread_mutex_lock(&m.handle) == 0);
}

// Returns false if someone else holds the lock.
mutex_try_lock :: proc(m: ^Mutex) -> bool {
	return unix.pthread_mutex_trylock(&m.handle) == 0;
}

mutex_unlock :: proc(m: ^Mutex) {
	assert(unix.pthread_mutex_unlock(&m.handle) == 0);
}


condition_init :: proc(c: ^Condition, mutex: ^Mutex) -> bool {
	// NOTE(tetra, 2019-11-01): POSIX OOM if we cannot init the attrs or the condition.
	attrs: unix.pthread_condattr_t;
	if unix.pthread_condattr_init(&attrs) != 0 {
		return false;
	}
	defer unix.pthread_condattr_destroy(&attrs); // ignores destruction error

	c.flag = false;
	c.mutex = mutex;
	return unix.pthread_cond_init(&c.handle, &attrs) == 0;
}

condition_destroy :: proc(c: ^Condition) {
	assert(unix.pthread_cond_destroy(&c.handle) == 0);
	c.handle = {};
}

// Awaken exactly one thread who is waiting on the condition
condition_signal :: proc(c: ^Condition) -> bool {
	mutex_lock(c.mutex);
	defer mutex_unlock(c.mutex);
	atomic_swap(&c.flag, true, .Sequentially_Consistent);
	return unix.pthread_cond_signal(&c.handle) == 0;
}

// Awaken all threads who are waiting on the condition
condition_broadcast :: proc(c: ^Condition) -> bool {
	return pthread_cond_broadcast(&c.handle) == 0;
}

// Wait for the condition to be signalled.
// Does not block if the condition has been signalled and no one
// has waited on it yet.
condition_wait_for :: proc(c: ^Condition) -> bool {
	mutex_lock(c.mutex);
	defer mutex_unlock(c.mutex);
	// NOTE(tetra): If a thread comes by and steals the flag immediately after the signal occurs,
	// the thread that gets signalled and wakes up, discovers that the flag was taken and goes
	// back to sleep.
	// Though this overall behavior is the most sane, there may be a better way to do this that means that
	// the first thread to wait, gets the flag first.
	if atomic_swap(&c.flag, false, .Sequentially_Consistent) {
		return true;
	}
	for {
		if unix.pthread_cond_wait(&c.handle, &c.mutex.handle) != 0 {
			return false;
		}
		if atomic_swap(&c.flag, false, .Sequentially_Consistent) {
			return true;
		}
	}

	return false;
}
