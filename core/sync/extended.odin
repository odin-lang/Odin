package sync

import "core:time"
import vg "core:sys/valgrind"
_ :: vg

/*
Wait group.

Wait group is a synchronization primitive used by the waiting thread to wait,
until a all working threads finish work.

The waiting thread first sets the number of working threads it will expect to
wait for using `wait_group_add` call, and start waiting using `wait_group_wait`
call. When worker threads complete their work, each of them will call
`wait_group_done`, and after all working threads have called this procedure,
the waiting thread will resume execution.

For the purpose of keeping track whether all working threads have finished their
work, the wait group keeps an internal atomic counter. Initially, the waiting
thread might set it to a certain non-zero amount. When each working thread
completes the work, the internal counter is atomically decremented until it
reaches zero. When it reaches zero, the waiting thread is unblocked. The counter
is not allowed to become negative.

**Note**: Just like any synchronization primitives, a wait group cannot be
copied after first use. See documentation for `Mutex` or `Cond`.
*/
Wait_Group :: struct #no_copy {
	counter: int,
	mutex:   Mutex,
	cond:    Cond,
}

/*
Increment an internal counter of a wait group.

This procedure atomicaly increments a number to the specified wait group's
internal counter by a specified amount. This operation can be done on any
thread.
*/
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

/*
Signal work done by a thread in a wait group.

This procedure decrements the internal counter of the specified wait group and
wakes up the waiting thread. Once the internal counter reaches zero, the waiting
thread resumes execution.
*/
wait_group_done :: proc "contextless" (wg: ^Wait_Group) {
	wait_group_add(wg, -1)
}

/*
Wait for all worker threads in the wait group.

This procedure blocks the execution of the current thread, until the specified
wait group's internal counter reaches zero.
*/
wait_group_wait :: proc "contextless" (wg: ^Wait_Group) {
	guard(&wg.mutex)

	if wg.counter != 0 {
		cond_wait(&wg.cond, &wg.mutex)
		if wg.counter != 0 {
			_panic("sync.Wait_Group misuse: sync.wait_group_add called concurrently with sync.wait_group_wait")
		}
	}
}

/*
Wait for all worker threads in the wait group, or until timeout is reached.

This procedure blocks the execution of the current thread, until the specified
wait group's internal counter reaches zero, or until the timeout is reached.

This procedure returns `false`, if the timeout was reached, `true` otherwise.
*/
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
Barrier.

A barrier is a synchronization primitive enabling multiple threads to
synchronize the beginning of some computation.

When `barrier_wait` procedure is called by any thread, that thread will block
the execution, until all threads associated with the barrier reach the same
point of execution and also call `barrier_wait`.

when barrier is initialized, a `thread_count` parameter is passed, signifying
the amount of participant threads of the barrier. The barrier also keeps track
of an internal atomic counter. When a thread calls `barrier_wait`, the internal
counter is incremented. When the internal counter reaches `thread_count`, it is
reset and all threads waiting on the barrier are unblocked.

This type of synchronization primitive can be used to synchronize "staged"
workloads, where the workload is split into stages, and until all threads have
completed the previous threads, no thread is allowed to start work on the next
stage. In this case, after each stage, a `barrier_wait` shall be inserted in the
thread procedure.

**Example**:

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
		thread.destroy(t)
	}
*/
Barrier :: struct #no_copy {
	mutex: Mutex,
	cond:  Cond,
	index:         int,
	generation_id: int,
	thread_count:  int,
}

/*
Initialize a barrier.


This procedure initializes the barrier for the specified amount of participant
threads.
*/
barrier_init :: proc "contextless" (b: ^Barrier, thread_count: int) {
	when ODIN_VALGRIND_SUPPORT {
		vg.helgrind_barrier_resize_pre(b, uint(thread_count))
	}
	b.index = 0
	b.generation_id = 0
	b.thread_count = thread_count
}

/*
Block the current thread until all threads have rendezvoused.

This procedure blocks the execution of the current thread, until all threads
have reached the same point in the execution of the thread proc. Multiple calls
to `barrier_wait` are allowed within the thread procedure.
*/
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

/*
Auto-reset event.

Represents a thread synchronization primitive that, when signalled, releases one
single waiting thread and then resets automatically to a state where it can be
signalled again.

When a thread calls `auto_reset_event_wait`, it's execution will be blocked,
until the event is signalled by another thread. The call to
`auto_reset_event_signal` wakes up exactly one thread waiting for the event.
*/
Auto_Reset_Event :: struct #no_copy {
	// status ==  0: Event is reset and no threads are waiting
	// status ==  1: Event is signalled
	// status == -N: Event is reset and N threads are waiting
	status: i32,
	sema:   Sema,
}

/*
Signal an auto-reset event.

This procedure signals an auto-reset event, waking up exactly one waiting
thread.
*/
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

/*
Wait on an auto-reset event.

This procedure blocks the execution of the current thread, until the event is
signalled by another thread.
*/
auto_reset_event_wait :: proc "contextless" (e: ^Auto_Reset_Event) {
	old_status := atomic_sub_explicit(&e.status, 1, .Acquire)
	if old_status < 1 {
		sema_wait(&e.sema)
	}
}

/*
Ticket lock.

A ticket lock is a mutual exclusion lock that uses "tickets" to control which
thread is allowed into a critical section.

This synchronization primitive works just like spinlock, except that it implements
a "fairness" guarantee, making sure that each thread gets a roughly equal amount
of entries into the critical section.

This type of synchronization primitive is applicable for short critical sections
in low-contention systems, as it uses a spinlock under the hood.
*/
Ticket_Mutex :: struct #no_copy {
	ticket:  uint,
	serving: uint,
}

/*
Acquire a lock on a ticket mutex.

This procedure acquires a lock on a ticket mutex. If the ticket mutex is held
by another thread, this procedure also blocks the execution until the lock
can be acquired.

Once the lock is acquired, any thread calling `ticket_mutex_lock` will be
blocked from entering any critical sections associated with the same ticket
mutex, until the lock is released.
*/
ticket_mutex_lock :: #force_inline proc "contextless" (m: ^Ticket_Mutex) {
	ticket := atomic_add_explicit(&m.ticket, 1, .Relaxed)
	for ticket != atomic_load_explicit(&m.serving, .Acquire) {
		cpu_relax()
	}
}

/*
Release a lock on a ticket mutex.

This procedure releases the lock on a ticket mutex. If any of the threads are
waiting to acquire the lock, exactly one of those threads is unblocked and
allowed into the critical section.
*/
ticket_mutex_unlock :: #force_inline proc "contextless" (m: ^Ticket_Mutex) {
	atomic_add_explicit(&m.serving, 1, .Relaxed)
}

/*
Guard the current scope with a lock on a ticket mutex.

This procedure acquires a lock on a ticket mutex. The lock is automatically
released at the end of callee's scope. If the mutex was already locked, this
procedure also blocks until the lock can be acquired.

When a lock has been acquired, all threads attempting to acquire a lock will be
blocked from entering any critical sections associated with the ticket mutex,
until the lock is released.

This procedure always returns `true`. This makes it easy to define a critical
section by putting the function inside the `if` statement.

**Example**:

	if ticket_mutex_guard(&m) {
		...
	}
*/
@(deferred_in=ticket_mutex_unlock)
ticket_mutex_guard :: proc "contextless" (m: ^Ticket_Mutex) -> bool {
	ticket_mutex_lock(m)
	return true
}

/*
Benaphore.

A benaphore is a combination of an atomic variable and a semaphore that can
improve locking efficiency in a no-contention system. Acquiring a benaphore
lock doesn't call into an internal semaphore, if no other thread in a middle of
a critical section.

Once a lock on a benaphore is acquired by a thread, no other thread is allowed
into any critical sections, associted with the same benaphore, until the lock
is released.
*/
Benaphore :: struct #no_copy {
	counter: i32,
	sema:    Sema,
}

/*
Acquire a lock on a benaphore.

This procedure acquires a lock on the specified benaphore. If the lock on a
benaphore is already held, this procedure also blocks the execution of the
current thread, until the lock could be acquired.

Once a lock is acquired, all threads attempting to take a lock will be blocked
from entering any critical sections associated with the same benaphore, until
until the lock is released.
*/
benaphore_lock :: proc "contextless" (b: ^Benaphore) {
	if atomic_add_explicit(&b.counter, 1, .Acquire) > 1 {
		sema_wait(&b.sema)
	}
}

/*
Try to acquire a lock on a benaphore.

This procedure tries to acquire a lock on the specified benaphore. If it was
already locked, then the returned value is `false`, otherwise the lock is
acquired and the procedure returns `true`.

If the lock is acquired, all threads that attempt to acquire a lock will be
blocked from entering any critical sections associated with the same benaphore,
until the lock is released.
*/
benaphore_try_lock :: proc "contextless" (b: ^Benaphore) -> bool {
	v, _ := atomic_compare_exchange_strong_explicit(&b.counter, 0, 1, .Acquire, .Acquire)
	return v == 0
}

/*
Release a lock on a benaphore.

This procedure releases a lock on the specified benaphore. If any of the threads
are waiting on the lock, exactly one thread is allowed into a critical section
associated with the same banaphore.
*/
benaphore_unlock :: proc "contextless" (b: ^Benaphore) {
	if atomic_sub_explicit(&b.counter, 1, .Release) > 0 {
		sema_post(&b.sema)
	}
}

/*
Guard the current scope with a lock on a benaphore.

This procedure acquires a lock on a benaphore. The lock is automatically
released at the end of callee's scope. If the benaphore was already locked, this
procedure also blocks until the lock can be acquired.

When a lock has been acquired, all threads attempting to acquire a lock will be
blocked from entering any critical sections associated with the same benaphore,
until the lock is released.

This procedure always returns `true`. This makes it easy to define a critical
section by putting the function inside the `if` statement.

**Example**:

	if benaphore_guard(&m) {
		...
	}
*/
@(deferred_in=benaphore_unlock)
benaphore_guard :: proc "contextless" (m: ^Benaphore) -> bool {
	benaphore_lock(m)
	return true
}

/*
Recursive benaphore.

Recurisve benaphore is just like a plain benaphore, except it allows reentrancy
into the critical section.

When a lock is acquired on a benaphore, all other threads attempting to
acquire a lock on the same benaphore will be blocked from any critical sections,
associated with the same benaphore.

When a lock is acquired on a benaphore by a thread, that thread is allowed
to acquire another lock on the same benaphore. When a thread has acquired the
lock on a benaphore, the benaphore will stay locked until the thread releases
the lock as many times as it has been locked by the thread.
*/
Recursive_Benaphore :: struct #no_copy {
	counter:   int,
	owner:     int,
	recursion: i32,
	sema:      Sema,
}

/*
Acquire a lock on a recursive benaphore.

This procedure acquires a lock on a recursive benaphore. If the benaphore is
held by another thread, this function blocks until the lock can be acquired.

Once a lock is acquired, all other threads attempting to acquire a lock will
be blocked from entering any critical sections associated with the same
recursive benaphore, until the lock is released.
*/
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

/*
Try to acquire a lock on a recursive benaphore.

This procedure attempts to acquire a lock on recursive benaphore. If the
benaphore is already held by a different thread, this procedure returns `false`.
Otherwise the lock is acquired and the procedure returns `true`.

If the lock is acquired, all other threads attempting to acquire a lock will
be blocked from entering any critical sections assciated with the same recursive
benaphore, until the lock is released.
*/
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

/*
Release a lock on a recursive benaphore.

This procedure releases a lock on the specified recursive benaphore. It also
causes the critical sections associated with the same benaphore, to become open
for other threads for entering.
*/
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

/*
Guard the current scope with a recursive benaphore.

This procedure acquires a lock on the specified recursive benaphores and
automatically releases it at the end of the callee's scope. If the recursive
benaphore was already held by a another thread, this procedure also blocks until
the lock can be acquired.

When the lock is acquired all other threads attempting to take a lock will be
blocked from entering any critical sections associated with the same benaphore,
until the lock is released.

This procedure always returns `true`, which makes it easy to define a critical
section by calling this procedure inside an `if` statement.

**Example**:

	if recursive_benaphore_guard(&m) {
		...
	}
*/
@(deferred_in=recursive_benaphore_unlock)
recursive_benaphore_guard :: proc "contextless" (m: ^Recursive_Benaphore) -> bool {
	recursive_benaphore_lock(m)
	return true
}

/*
Once action.

`Once` a synchronization primitive, that only allows a single entry into a
critical section from a single thread.
*/
Once :: struct #no_copy {
	m:    Mutex,
	done: bool,
}

/*
Call a function once.

The `once_do` procedure group calls a specified function, if it wasn't already
called from the perspective of a specific `Once` struct.
*/
once_do :: proc{
	once_do_without_data,
	once_do_without_data_contextless,
	once_do_with_data,
	once_do_with_data_contextless,
}

/*
Call a function with no data once.
*/
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

/*
Call a contextless function with no data once.
*/
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

/*
Call a function with data once.
*/
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

/*
Call a contextless function with data once.
*/
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

/*
A Parker is an associated token which is initially not present:

* The `park` procedure blocks the current thread unless or until the token
  is available, at which point the token is consumed.
* The `park_with_timeout` procedures works the same as `park` but only
  blocks for the specified duration.
* The `unpark` procedure automatically makes the token available if it
  was not already.
*/
Parker :: struct #no_copy {
	state: Futex,
}

@(private="file") PARKER_EMPTY    :: 0
@(private="file") PARKER_NOTIFIED :: 1
@(private="file") PARKER_PARKED   :: max(u32)

/*
Blocks until the token is available.

This procedure blocks the execution of the current thread, until a token is
made available.

**Note**: This procedure assumes this is only called by the thread that owns
the Parker.
*/
park :: proc "contextless" (p: ^Parker) {
	if atomic_sub_explicit(&p.state, 1, .Acquire) == PARKER_NOTIFIED {
		return
	}
	for {
		futex_wait(&p.state, PARKER_PARKED)
		if _, ok := atomic_compare_exchange_strong_explicit(&p.state, PARKER_NOTIFIED, PARKER_EMPTY, .Acquire, .Acquire); ok {
			return
		}
	}
}

/*
Blocks until the token is available with timeout.

This procedure blocks the execution of the current thread until a token is made
available, or until the timeout has expired, whatever happens first.

**Note**: This procedure assumes this is only called by the thread that owns
the Parker.
*/
park_with_timeout :: proc "contextless" (p: ^Parker, duration: time.Duration) {
	start_tick := time.tick_now()
	remaining_duration := duration
	if atomic_sub_explicit(&p.state, 1, .Acquire) == PARKER_NOTIFIED {
		return
	}
	for {
		if !futex_wait_with_timeout(&p.state, PARKER_PARKED, remaining_duration) {
			return
		}
		old, ok := atomic_compare_exchange_weak_explicit((^u32)(&p.state), PARKER_PARKED, PARKER_EMPTY, .Acquire, .Relaxed)
		if ok || old == PARKER_PARKED {
			return
		}
		end_tick := time.tick_now()
		remaining_duration -= time.tick_diff(start_tick, end_tick)
		start_tick = end_tick
	}
}

/*
Make the token available.
*/
unpark :: proc "contextless" (p: ^Parker)  {
	if atomic_exchange_explicit((^u32)(&p.state), PARKER_NOTIFIED, .Release) == PARKER_PARKED {
		futex_signal(&p.state)
	}
}

/*
One-shot event.

A one-shot event is an associated token which is initially not present:

* The `one_shot_event_wait` blocks the current thread until the event
  is made available
* The `one_shot_event_signal` procedure automatically makes the token
  available if its was not already.
*/
One_Shot_Event :: struct #no_copy {
	state: Futex,
}

/*
Block until the event is made available.

This procedure blocks the execution of the current thread, until the event is
made available.
*/
one_shot_event_wait :: proc "contextless" (e: ^One_Shot_Event) {
	for atomic_load_explicit(&e.state, .Acquire) == 0 {
		futex_wait(&e.state, 0)
	}
}

/*
Make event available.
*/
one_shot_event_signal :: proc "contextless" (e: ^One_Shot_Event) {
	atomic_store_explicit(&e.state, 1, .Release)
	futex_broadcast(&e.state)
}