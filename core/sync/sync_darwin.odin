package sync

import "core:sys/darwin"

import "core:c"

// The Darwin docs say it best:
// A semaphore is much like a lock, except that a finite number of threads can hold it simultaneously.
// Semaphores can be thought of as being much like piles of tokens; multiple threads can take these tokens, 
// but when there are none left, a thread must wait until another thread returns one.
Semaphore :: struct #align 16 {
	handle: darwin.semaphore_t,
}
// TODO(tetra): Only marked with alignment because we cannot mark distinct integers with alignments.
// See core/sys/unix/pthread_linux.odin/pthread_t.

semaphore_init :: proc(s: ^Semaphore, initial_count := 0) {
	ct := darwin.mach_task_self();
	res := darwin.semaphore_create(ct, &s.handle, 0, c.int(initial_count));
	assert(res == 0);
}

semaphore_destroy :: proc(s: ^Semaphore) {
	ct := darwin.mach_task_self();
	res := darwin.semaphore_destroy(ct, s.handle);
	assert(res == 0);
	s.handle = {};
}

semaphore_post :: proc(s: ^Semaphore, count := 1) {
	assert(count == 1);
	res := darwin.semaphore_signal(s.handle);
	assert(res == 0);
}

semaphore_wait_for :: proc(s: ^Semaphore) {
	res := darwin.semaphore_wait(s.handle);
	assert(res == 0);
}
