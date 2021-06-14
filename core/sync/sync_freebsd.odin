package sync

import "core:sys/unix"

foreign import libc "system:c"

current_thread_id :: proc "contextless" () -> int {
	foreign libc {
		syscall :: proc(number: i32, #c_vararg args: ..any) -> i32 ---
	}

	SYS_GETTID :: 186;
	return int(syscall(SYS_GETTID));
}


// The Darwin docs say it best:
// A semaphore is much like a lock, except that a finite number of threads can hold it simultaneously.
// Semaphores can be thought of as being much like piles of tokens; multiple threads can take these tokens, 
// but when there are none left, a thread must wait until another thread returns one.
Semaphore :: struct #align 16 {
	handle: unix.sem_t,
}

semaphore_init :: proc(s: ^Semaphore, initial_count := 0) {
	assert(unix.sem_init(&s.handle, 0, u32(initial_count)) == 0);
}

semaphore_destroy :: proc(s: ^Semaphore) {
	assert(unix.sem_destroy(&s.handle) == 0);
	s.handle = {};
}

semaphore_post :: proc(s: ^Semaphore, count := 1) {
    // NOTE: SPEED: If there's one syscall to do this, we should use it instead of the loop.
    for in 0..<count {
	    assert(unix.sem_post(&s.handle) == 0);
    }
}

semaphore_wait_for :: proc(s: ^Semaphore) {
	assert(unix.sem_wait(&s.handle) == 0);
}

