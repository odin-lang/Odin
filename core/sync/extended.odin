package sync

import "core:time"
import vg "core:sys/valgrind"
_ :: vg

// A Wait_Group waits for a collection of threads to finish
//
// A Wait_Group must not be copied after first use
Wait_Group :: struct #no_copy {
	counter: int,
	mutex:   Mutex,
	cond:    Cond,
}

wait_group_add :: proc "contextless" (wg: ^Wait_Group, delta: int) {
	if delta == 0 {
		return
	}

	guard(&wg.mutex)

	atomic_add(&wg.counter, delta)
	if wg.counter < 0 {
		_panic("sync.Wait_Group negative counter")
	}
	if wg.counter == 0 {
		cond_broadcast(&wg.cond)
		if wg.counter != 0 {
			_panic("sync.Wait_Group misuse: sync.wait_group_add called concurrently with sync.wait_group_wait")
		}
	}
}

wait_group_done :: proc "contextless" (wg: ^Wait_Group) {
	wait_group_add(wg, -1)
}

wait_group_wait :: proc "contextless" (wg: ^Wait_Group) {
	guard(&wg.mutex)

	if wg.counter != 0 {
		cond_wait(&wg.cond, &wg.mutex)
		if wg.counter != 0 {
			_panic("sync.Wait_Group misuse: sync.wait_group_add called concurrently with sync.wait_group_wait")
		}
	}
}

wait_group_wait_with_timeout :: proc "contextless" (wg: ^Wait_Group, duration: time.Duration) -> bool {
	if duration <= 0 {
		return false
	}
	guard(&wg.mutex)

	if wg.counter != 0 {
		if !cond_wait_with_timeout(&wg.cond, &wg.mutex, duration) {
			return false
		}
		if wg.counter != 0 {
			_panic("sync.Wait_Group misuse: sync.wait_group_add called concurrently with sync.wait_group_wait")
		}
	}
	return true
}



/*
A barrier enabling multiple threads to synchronize the beginning of some computation

Example:
	package example

	import "core:fmt"
	import "core:sync"
	import "core:thread"

	barrier := &sync.Barrier{}

	main :: proc "contextless" () {
		fmt.println("Start")

		THREAD_COUNT :: 4
		threads: [THREAD_COUNT]^thread.Thread

		sync.barrier_init(barrier, THREAD_COUNT)

		for _, i in threads {
			threads[i] = thread.create_and_start(proc(t: ^thread.Thread) {
				// Same messages will be printed together but without any interleaving
				fmt.println("Getting ready!")
				sync.barrier_wait(barrier)
				fmt.println("Off their marks they go!")
			})
		}

		for t in threads {
			thread.destroy(t) // join and free thread
		}
		fmt.println("Finished")
	}
*/
Barrier :: struct #no_copy {
	mutex: Mutex,
	cond:  Cond,
	index:         int,
	generation_id: int,
	thread_count:  int,
}

barrier_init :: proc "contextless" (b: ^Barrier, thread_count: int) {
	when ODIN_VALGRIND_SUPPORT {
		vg.helgrind_barrier_resize_pre(b, uint(thread_count))
	}
	b.index = 0
	b.generation_id = 0
	b.thread_count = thread_count
}

// Block the current thread until all threads have rendezvoused
// Barrier can be reused after all threads rendezvoused once, and can be used continuously
barrier_wait :: proc "contextless" (b: ^Barrier) -> (is_leader: bool) {
	when ODIN_VALGRIND_SUPPORT {
		vg.helgrind_barrier_wait_pre(b)
	}
	guard(&b.mutex)
	local_gen := b.generation_id
	b.index += 1
	if b.index < b.thread_count {
		for local_gen == b.generation_id && b.index < b.thread_count {
			cond_wait(&b.cond, &b.mutex)
		}
		return false
	}

	b.index = 0
	b.generation_id += 1
	cond_broadcast(&b.cond)
	return true
}


Auto_Reset_Event :: struct #no_copy {
	// status ==  0: Event is reset and no threads are waiting
	// status ==  1: Event is signaled
	// status == -N: Event is reset and N threads are waiting
	status: i32,
	sema:   Sema,
}

auto_reset_event_signal :: proc "contextless" (e: ^Auto_Reset_Event) {
	old_status := atomic_load_explicit(&e.status, .Relaxed)
	for {
		new_status := old_status + 1 if old_status < 1 else 1
		if _, ok := atomic_compare_exchange_weak_explicit(&e.status, old_status, new_status, .Release, .Relaxed); ok {
			break
		}

		if old_status < 0 {
			sema_post(&e.sema)
		}
	}
}

auto_reset_event_wait :: proc "contextless" (e: ^Auto_Reset_Event) {
	old_status := atomic_sub_explicit(&e.status, 1, .Acquire)
	if old_status < 1 {
		sema_wait(&e.sema)
	}
}



Ticket_Mutex :: struct #no_copy {
	ticket:  uint,
	serving: uint,
}

ticket_mutex_lock :: #force_inline proc "contextless" (m: ^Ticket_Mutex) {
	ticket := atomic_add_explicit(&m.ticket, 1, .Relaxed)
	for ticket != atomic_load_explicit(&m.serving, .Acquire) {
		cpu_relax()
	}
}

ticket_mutex_unlock :: #force_inline proc "contextless" (m: ^Ticket_Mutex) {
	atomic_add_explicit(&m.serving, 1, .Relaxed)
}
@(deferred_in=ticket_mutex_unlock)
ticket_mutex_guard :: proc "contextless" (m: ^Ticket_Mutex) -> bool {
	ticket_mutex_lock(m)
	return true
}


Benaphore :: struct #no_copy {
	counter: i32,
	sema:    Sema,
}

benaphore_lock :: proc "contextless" (b: ^Benaphore) {
	if atomic_add_explicit(&b.counter, 1, .Acquire) > 1 {
		sema_wait(&b.sema)
	}
}

benaphore_try_lock :: proc "contextless" (b: ^Benaphore) -> bool {
	v, _ := atomic_compare_exchange_strong_explicit(&b.counter, 0, 1, .Acquire, .Acquire)
	return v == 0
}

benaphore_unlock :: proc "contextless" (b: ^Benaphore) {
	if atomic_sub_explicit(&b.counter, 1, .Release) > 0 {
		sema_post(&b.sema)
	}
}

@(deferred_in=benaphore_unlock)
benaphore_guard :: proc "contextless" (m: ^Benaphore) -> bool {
	benaphore_lock(m)
	return true
}

Recursive_Benaphore :: struct #no_copy {
	counter:   int,
	owner:     int,
	recursion: i32,
	sema:      Sema,
}

recursive_benaphore_lock :: proc "contextless" (b: ^Recursive_Benaphore) {
	tid := current_thread_id()
	if atomic_add_explicit(&b.counter, 1, .Acquire) > 1 {
		if tid != b.owner {
			sema_wait(&b.sema)
		}
	}
	// inside the lock
	b.owner = tid
	b.recursion += 1
}

recursive_benaphore_try_lock :: proc "contextless" (b: ^Recursive_Benaphore) -> bool {
	tid := current_thread_id()
	if b.owner == tid {
		atomic_add_explicit(&b.counter, 1, .Acquire)
	}

	if v, _ := atomic_compare_exchange_strong_explicit(&b.counter, 0, 1, .Acquire, .Acquire); v != 0 {
		return false
	}
	// inside the lock
	b.owner = tid
	b.recursion += 1
	return true
}

recursive_benaphore_unlock :: proc "contextless" (b: ^Recursive_Benaphore) {
	tid := current_thread_id()
	_assert(tid == b.owner, "tid != b.owner")
	b.recursion -= 1
	recursion := b.recursion
	if recursion == 0 {
		b.owner = 0
	}
	if atomic_sub_explicit(&b.counter, 1, .Release) > 0 {
		if recursion == 0 {
			sema_post(&b.sema)
		}
	}
	// outside the lock
}

@(deferred_in=recursive_benaphore_unlock)
recursive_benaphore_guard :: proc "contextless" (m: ^Recursive_Benaphore) -> bool {
	recursive_benaphore_lock(m)
	return true
}




// Once is a data value that will perform exactly on action.
// 
// A Once must not be copied after first use.
Once :: struct #no_copy {
	m:    Mutex,
	done: bool,
}

// once_do calls the procedure fn if and only if once_do is being called for the first for this instance of Once.
once_do :: proc{
	once_do_without_data,
	once_do_without_data_contextless,
	once_do_with_data,
	once_do_with_data_contextless,
}

// once_do_without_data calls the procedure fn if and only if once_do_without_data is being called for the first for this instance of Once.
once_do_without_data :: proc(o: ^Once, fn: proc()) {
	@(cold)
	do_slow :: proc(o: ^Once, fn: proc()) {
		guard(&o.m)
		if !o.done {
			fn()
			atomic_store_explicit(&o.done, true, .Release)
		}
	}

	if atomic_load_explicit(&o.done, .Acquire) == false {
		do_slow(o, fn)
	}
}

// once_do_without_data calls the procedure fn if and only if once_do_without_data is being called for the first for this instance of Once.
once_do_without_data_contextless :: proc(o: ^Once, fn: proc "contextless" ()) {
	@(cold)
	do_slow :: proc(o: ^Once, fn: proc "contextless" ()) {
		guard(&o.m)
		if !o.done {
			fn()
			atomic_store_explicit(&o.done, true, .Release)
		}
	}

	if atomic_load_explicit(&o.done, .Acquire) == false {
		do_slow(o, fn)
	}
}

// once_do_with_data calls the procedure fn if and only if once_do_with_data is being called for the first for this instance of Once.
once_do_with_data :: proc(o: ^Once, fn: proc(data: rawptr), data: rawptr) {
	@(cold)
	do_slow :: proc(o: ^Once, fn: proc(data: rawptr), data: rawptr) {
		guard(&o.m)
		if !o.done {
			fn(data)
			atomic_store_explicit(&o.done, true, .Release)
		}
	}

	if atomic_load_explicit(&o.done, .Acquire) == false {
		do_slow(o, fn, data)
	}
}

// once_do_with_data_contextless calls the procedure fn if and only if once_do_with_data_contextless is being called for the first for this instance of Once.
once_do_with_data_contextless :: proc "contextless" (o: ^Once, fn: proc "contextless" (data: rawptr), data: rawptr) {
	@(cold)
	do_slow :: proc "contextless" (o: ^Once, fn: proc "contextless" (data: rawptr), data: rawptr) {
		guard(&o.m)
		if !o.done {
			fn(data)
			atomic_store_explicit(&o.done, true, .Release)
		}
	}

	if atomic_load_explicit(&o.done, .Acquire) == false {
		do_slow(o, fn, data)
	}
}





// A Parker is an associated token which is initially not present:
//     * The `park` procedure blocks the current thread unless or until the token
//       is available, at which point the token is consumed.
//     * The `park_with_timeout` procedures works the same as `park` but only
//       blocks for the specified duration.
//     * The `unpark` procedure automatically makes the token available if it
//       was not already.
Parker :: struct #no_copy {
	state: Futex,
}

// Blocks the current thread until the token is made available.
//
// Assumes this is only called by the thread that owns the Parker.
park :: proc "contextless" (p: ^Parker) {
	EMPTY    :: 0
	NOTIFIED :: 1
	PARKED   :: max(u32)
	if atomic_sub_explicit(&p.state, 1, .Acquire) == NOTIFIED {
		return
	}
	for {
		futex_wait(&p.state, PARKED)
		if _, ok := atomic_compare_exchange_strong_explicit(&p.state, NOTIFIED, EMPTY, .Acquire, .Acquire); ok {
			return
		}
	}
}

// Blocks the current thread until the token is made available, but only
// for a limited duration.
//
// Assumes this is only called by the thread that owns the Parker
park_with_timeout :: proc "contextless" (p: ^Parker, duration: time.Duration) {
	EMPTY    :: 0
	NOTIFIED :: 1
	PARKED   :: max(u32)
	if atomic_sub_explicit(&p.state, 1, .Acquire) == NOTIFIED {
		return
	}
	futex_wait_with_timeout(&p.state, PARKED, duration)
	atomic_exchange_explicit(&p.state, EMPTY, .Acquire)
}

// Automatically makes thee token available if it was not already.
unpark :: proc "contextless" (p: ^Parker)  {
	EMPTY    :: 0
	NOTIFIED :: 1
	PARKED   :: max(Futex)
	if atomic_exchange_explicit(&p.state, NOTIFIED, .Release) == PARKED {
		futex_signal(&p.state)
	}
}



// A One_Shot_Event is an associated token which is initially not present:
//     * The `one_shot_event_wait` blocks the current thread until the event
//       is made available
//     * The `one_shot_event_signal` procedure automatically makes the token
//       available if its was not already.
One_Shot_Event :: struct #no_copy {
	state: Futex,
}

// Blocks the current thread until the event is made available with `one_shot_event_signal`.
one_shot_event_wait :: proc "contextless" (e: ^One_Shot_Event) {
	for atomic_load_explicit(&e.state, .Acquire) == 0 {
		futex_wait(&e.state, 0)
	}
}

// Releases any threads that are currently blocked by this event with `one_shot_event_wait`.
one_shot_event_signal :: proc "contextless" (e: ^One_Shot_Event) {
	atomic_store_explicit(&e.state, 1, .Release)
	futex_broadcast(&e.state)
}