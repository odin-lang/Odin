package sync

import "intrinsics"
import "core:runtime"

cpu_relax :: #force_inline proc "contextless" () {
	intrinsics.cpu_relax();
}

Condition_Mutex_Ptr :: union{^Mutex, ^Blocking_Mutex};


Ticket_Mutex :: struct {
	ticket:  u64,
	serving: u64,
}

ticket_mutex_init :: proc(m: ^Ticket_Mutex) {
	atomic_store(&m.ticket,  0, .Relaxed);
	atomic_store(&m.serving, 0, .Relaxed);
}

ticket_mutex_lock :: #force_inline proc(m: ^Ticket_Mutex) {
	ticket := atomic_add(&m.ticket, 1, .Relaxed);
	for ticket != atomic_load(&m.serving, .Acquire) {
		intrinsics.cpu_relax();
	}
}

ticket_mutex_unlock :: #force_inline proc(m: ^Ticket_Mutex) {
	atomic_add(&m.serving, 1, .Relaxed);
}


Benaphore :: struct {
	counter: int,
	sema: Semaphore,
}

benaphore_init :: proc(b: ^Benaphore) {
	intrinsics.atomic_store(&b.counter, 0);
	semaphore_init(&b.sema);
}

benaphore_destroy :: proc(b: ^Benaphore) {
	semaphore_destroy(&b.sema);
}

benaphore_lock :: proc(b: ^Benaphore) {
	if intrinsics.atomic_add_acq(&b.counter, 1) > 1 {
		semaphore_wait_for(&b.sema);
	}
}

benaphore_try_lock :: proc(b: ^Benaphore) -> bool {
	v, _ := intrinsics.atomic_cxchg_acq(&b.counter, 1, 0);
	return v == 0;
}

benaphore_unlock :: proc(b: ^Benaphore) {
	if intrinsics.atomic_sub_rel(&b.counter, 1) > 0 {
		semaphore_post(&b.sema);
	}
}

Recursive_Benaphore :: struct {
	counter:   int,
	owner:     int,
	recursion: int,
	sema: Semaphore,
}

recursive_benaphore_init :: proc(b: ^Recursive_Benaphore) {
	intrinsics.atomic_store(&b.counter, 0);
	semaphore_init(&b.sema);
}

recursive_benaphore_destroy :: proc(b: ^Recursive_Benaphore) {
	semaphore_destroy(&b.sema);
}

recursive_benaphore_lock :: proc(b: ^Recursive_Benaphore) {
	tid := runtime.current_thread_id();
	if intrinsics.atomic_add_acq(&b.counter, 1) > 1 {
		if tid != b.owner {
			semaphore_wait_for(&b.sema);
		}
	}
	// inside the lock
	b.owner = tid;
	b.recursion += 1;
}

recursive_benaphore_try_lock :: proc(b: ^Recursive_Benaphore) -> bool {
	tid := runtime.current_thread_id();
	if b.owner == tid {
		intrinsics.atomic_add_acq(&b.counter, 1);
	} else {
		v, _ := intrinsics.atomic_cxchg_acq(&b.counter, 1, 0);
		if v != 0 {
			return false;
		}
		// inside the lock
		b.owner = tid;
	}
	b.recursion += 1;
	return true;
}

recursive_benaphore_unlock :: proc(b: ^Recursive_Benaphore) {
	tid := runtime.current_thread_id();
	assert(tid == b.owner);
	b.recursion -= 1;
	recursion := b.recursion;
	if recursion == 0 {
		b.owner = 0;
	}
	if intrinsics.atomic_sub_rel(&b.counter, 1) > 0 {
		if recursion == 0 {
			semaphore_post(&b.sema);
		}
	}
	// outside the lock
}
