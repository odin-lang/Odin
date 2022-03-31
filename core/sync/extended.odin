package sync

import "core:time"

// A Wait_Group waits for a collection of threads to finish
//
// A Wait_Group must not be copied after first use
Wait_Group :: struct {
	counter: int,
	mutex:   Mutex,
	cond:    Cond,
}

wait_group_add :: proc(wg: ^Wait_Group, delta: int) {
	if delta == 0 {
		return
	}

	mutex_lock(&wg.mutex)
	defer mutex_unlock(&wg.mutex)

	atomic_add(&wg.counter, delta)
	if wg.counter < 0 {
		panic("sync.Wait_Group negative counter")
	}
	if wg.counter == 0 {
		cond_broadcast(&wg.cond)
		if wg.counter != 0 {
			panic("sync.Wait_Group misuse: sync.wait_group_add called concurrently with sync.wait_group_wait")
		}
	}
}

wait_group_done :: proc(wg: ^Wait_Group) {
	wait_group_add(wg, -1)
}

wait_group_wait :: proc(wg: ^Wait_Group) {
	mutex_lock(&wg.mutex)
	defer mutex_unlock(&wg.mutex)

	if wg.counter != 0 {
		cond_wait(&wg.cond, &wg.mutex)
		if wg.counter != 0 {
			panic("sync.Wait_Group misuse: sync.wait_group_add called concurrently with sync.wait_group_wait")
		}
	}
}

wait_group_wait_with_timeout :: proc(wg: ^Wait_Group, duration: time.Duration) -> bool {
	if duration <= 0 {
		return false
	}
	mutex_lock(&wg.mutex)
	defer mutex_unlock(&wg.mutex)

	if wg.counter != 0 {
		if !cond_wait_with_timeout(&wg.cond, &wg.mutex, duration) {
			return false
		}
		if wg.counter != 0 {
			panic("sync.Wait_Group misuse: sync.wait_group_add called concurrently with sync.wait_group_wait")
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

	main :: proc() {
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
Barrier :: struct {
	mutex: Mutex,
	cond:  Cond,
	index:         int,
	generation_id: int,
	thread_count:  int,
}

barrier_init :: proc(b: ^Barrier, thread_count: int) {
	b.index = 0
	b.generation_id = 0
	b.thread_count = thread_count
}

// Block the current thread until all threads have rendezvoused
// Barrier can be reused after all threads rendezvoused once, and can be used continuously
barrier_wait :: proc(b: ^Barrier) -> (is_leader: bool) {
	mutex_lock(&b.mutex)
	defer mutex_unlock(&b.mutex)
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


Auto_Reset_Event :: struct {
	// status ==  0: Event is reset and no threads are waiting
	// status ==  1: Event is signaled
	// status == -N: Event is reset and N threads are waiting
	status: i32,
	sema:   Sema,
}

auto_reset_event_signal :: proc(e: ^Auto_Reset_Event) {
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

auto_reset_event_wait :: proc(e: ^Auto_Reset_Event) {
	old_status := atomic_sub_explicit(&e.status, 1, .Acquire)
	if old_status < 1 {
		sema_wait(&e.sema)
	}
}



Ticket_Mutex :: struct {
	ticket:  uint,
	serving: uint,
}

ticket_mutex_lock :: #force_inline proc(m: ^Ticket_Mutex) {
	ticket := atomic_add_explicit(&m.ticket, 1, .Relaxed)
	for ticket != atomic_load_explicit(&m.serving, .Acquire) {
		cpu_relax()
	}
}

ticket_mutex_unlock :: #force_inline proc(m: ^Ticket_Mutex) {
	atomic_add_explicit(&m.serving, 1, .Relaxed)
}
@(deferred_in=ticket_mutex_unlock)
ticket_mutex_guard :: proc(m: ^Ticket_Mutex) -> bool {
	ticket_mutex_lock(m)
	return true
}


Benaphore :: struct {
	counter: i32,
	sema:    Sema,
}

benaphore_lock :: proc(b: ^Benaphore) {
	if atomic_add_explicit(&b.counter, 1, .Acquire) > 1 {
		sema_wait(&b.sema)
	}
}

benaphore_try_lock :: proc(b: ^Benaphore) -> bool {
	v, _ := atomic_compare_exchange_strong_explicit(&b.counter, 1, 0, .Acquire, .Acquire)
	return v == 0
}

benaphore_unlock :: proc(b: ^Benaphore) {
	if atomic_sub_explicit(&b.counter, 1, .Release) > 0 {
		sema_post(&b.sema)
	}
}

@(deferred_in=benaphore_unlock)
benaphore_guard :: proc(m: ^Benaphore) -> bool {
	benaphore_lock(m)
	return true
}

Recursive_Benaphore :: struct {
	counter:   int,
	owner:     int,
	recursion: i32,
	sema:      Sema,
}

recursive_benaphore_lock :: proc(b: ^Recursive_Benaphore) {
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

recursive_benaphore_try_lock :: proc(b: ^Recursive_Benaphore) -> bool {
	tid := current_thread_id()
	if b.owner == tid {
		atomic_add_explicit(&b.counter, 1, .Acquire)
	}

	if v, _ := atomic_compare_exchange_strong_explicit(&b.counter, 1, 0, .Acquire, .Acquire); v != 0 {
		return false
	}
	// inside the lock
	b.owner = tid
	b.recursion += 1
	return true
}

recursive_benaphore_unlock :: proc(b: ^Recursive_Benaphore) {
	tid := current_thread_id()
	assert(tid == b.owner)
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
recursive_benaphore_guard :: proc(m: ^Recursive_Benaphore) -> bool {
	recursive_benaphore_lock(m)
	return true
}




// Once is a data value that will perform exactly on action.
// 
// A Once must not be copied after first use.
Once :: struct {
	m:    Mutex,
	done: bool,
}

// once_do calls the procedure fn if and only if once_do is being called for the first for this instance of Once.
once_do :: proc(o: ^Once, fn: proc()) {
	@(cold)
	do_slow :: proc(o: ^Once, fn: proc()) {
		mutex_lock(&o.m)
		defer mutex_unlock(&o.m)
		if !o.done {
			fn()
			atomic_store_explicit(&o.done, true, .Release)
		}
	}

	
	if atomic_load_explicit(&o.done, .Acquire) == false {
		do_slow(o, fn)
	}
}
