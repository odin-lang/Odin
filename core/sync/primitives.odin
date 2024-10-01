package sync

import "core:time"

/*
Obtain the current thread ID.
*/
current_thread_id :: proc "contextless" () -> int {
	return _current_thread_id()
}

/*
Mutual exclusion lock.

A Mutex is a [[mutual exclusion lock; https://en.wikipedia.org/wiki/Mutual_exclusion]]
It can be used to prevent more than one thread from entering the critical
section, and thus prevent access to same piece of memory by multiple threads, at
the same time.

Mutex's zero-initializzed value represents an initial, *unlocked* state.
 
If another thread tries to acquire the lock, while it's already held (typically
by another thread), the thread's execution will be blocked, until the lock is
released. Code or memory that is "surrounded" by a mutex lock and unlock
operations is said to be "guarded by a mutex".

**Note**: A Mutex must not be copied after first use (e.g., after locking it the
first time). This is because, in order to coordinate with other threads, all
threads must watch the same memory address to know when the lock has been
released. Trying to use a copy of the lock at a different memory address will
result in broken and unsafe behavior. For this reason, Mutexes are marked as
`#no_copy`.

**Note**: If the current thread attempts to lock a mutex, while it's already
holding another lock, that will cause a trivial case of deadlock. Do not use
`Mutex` in recursive functions. In case multiple locks by the same thread are
desired, use `Recursive_Mutex`.
*/
Mutex :: struct #no_copy {
	impl: _Mutex,
}

/*
Acquire a lock on a mutex.

This procedure acquires a lock with the specified mutex. If the mutex has been
already locked by any thread, this procedure also blocks until the lock can be
acquired.

Once the lock is acquired, all other threads that attempt to acquire a lock will
be blocked from entering any critical sections associated with the same mutex,
until the the lock is released.

**Note**: If the mutex is already locked by the current thread, a call to this
procedure will block indefinately. Do not use this in recursive procedures.
*/
mutex_lock :: proc "contextless" (m: ^Mutex) {
	_mutex_lock(m)
}

/*
Release a lock on a mutex.

This procedure releases the lock associated with the specified mutex. If the
mutex was not locked, this operation is a no-op.

When the current thread, that holds a lock to the mutex calls `mutex_unlock`,
this allows one other thread waiting on the mutex to enter any critical sections
associated with the mutex. If there are no threads waiting on the mutex, the
critical sections will remain open.
*/
mutex_unlock :: proc "contextless" (m: ^Mutex) {
	_mutex_unlock(m)
}

/*
Try to acquire a lock on a mutex.

This procedure tries to acquire a lock on the specified mutex. If it was already
locked, then the returned value is `false`, otherwise the lock is acquired and
the procedure returns `true`.

If the lock is acquired, all threads that attempt to acquire a lock will be
blocked from entering any critical sections associated with the same mutex,
until the lock is released.
*/
mutex_try_lock :: proc "contextless" (m: ^Mutex) -> bool {
	return _mutex_try_lock(m)
}

/*
Guard the current scope with a lock on a mutex.

This procedure acquires a mutex lock. The lock is automatically released
at the end of callee's scope. If the mutex was already locked, this procedure
also blocks until the lock can be acquired.

When a lock has been acquired, all threads attempting to acquire a lock will be
blocked from entering any critical sections associated with the mutex, until
the lock is released.

This procedure always returns `true`. This makes it easy to define a critical
section by putting the function inside the `if` statement.

**Example**:

	if mutex_guard(&m) {
		...
	}
*/
@(deferred_in=mutex_unlock)
mutex_guard :: proc "contextless" (m: ^Mutex) -> bool {
	mutex_lock(m)
	return true
}

/*
Read-write mutual exclusion lock.

An `RW_Mutex` is a reader/writer mutual exclusion lock. The lock can be held by
any number of readers or a single writer.

This type of synchronization primitive supports two kinds of lock operations:

- Exclusive lock (write lock)
- Shared lock (read lock)

When an exclusive lock is acquired by any thread, all other threads, attempting
to acquire either an exclusive or shared lock, will be blocked from entering the
critical sections associated with the read-write mutex, until the exclusive
owner of the lock releases the lock.

When a shared lock is acquired by any thread, any other thread attempting to
acquire a shared lock will also be able to enter all the critical sections
associated with the read-write mutex. However threads attempting to acquire
an exclusive lock will be blocked from entering those critical sections, until
all shared locks are released.

**Note**: A read-write mutex must not be copied after first use (e.g., after
acquiring a lock). This is because, in order to coordinate with other threads,
all threads must watch the same memory address to know when the lock has been
released. Trying to use a copy of the lock at a different memory address will
result in broken and unsafe behavior. For this reason, mutexes are marked as
`#no_copy`.

**Note**: A read-write mutex is not recursive. Do not attempt to acquire an
exclusive lock more than once from the same thread, or an exclusive and shared
lock on the same thread. Taking a shared lock multiple times is acceptable.
*/
RW_Mutex :: struct #no_copy {
	impl: _RW_Mutex,
}

/*
Acquire an exclusive lock.

This procedure acquires an exclusive lock on the specified read-write mutex. If
the lock is already held by any thread, this procedure also blocks until the
lock can be acquired.

After a lock has been acquired, any thread attempting to acquire any lock
will be blocked from entering any critical sections associated with the same
read-write mutex, until the exclusive lock is released.
*/
rw_mutex_lock :: proc "contextless" (rw: ^RW_Mutex) {
	_rw_mutex_lock(rw)
}

/*
Release an exclusive lock.

This procedure releases an exclusive lock associated with the specified
read-write mutex.

When the exclusive lock is released, all critical sections, associated with the
same read-write mutex, become open to other threads.
*/
rw_mutex_unlock :: proc "contextless" (rw: ^RW_Mutex) {
	_rw_mutex_unlock(rw)
}

/*
Try to acquire an exclusive lock on a read-write mutex.

This procedure tries to acquire an exclusive lock on the specified read-write
mutex. If the mutex was already locked, the procedure returns `false`. Otherwise
it acquires the exclusive lock and returns `true`.

If the lock has been acquired, all threads attempting to acquire any lock
will be blocked from entering any critical sections associated with the same
read-write mutex, until the exclusive locked is released.
*/
rw_mutex_try_lock :: proc "contextless" (rw: ^RW_Mutex) -> bool {
	return _rw_mutex_try_lock(rw)
}

/*
Acquire a shared lock on a read-write mutex.

This procedure acquires a shared lock on the specified read-write mutex. If the
mutex already has an exclusive lock held, this procedure also blocks until the
lock can be acquired.

After the shared lock is obtained, all threads attempting to acquire an
exclusive lock will be blocked from entering any critical sections associated
with the same read-write mutex, until all shared locks associated with the
specified read-write mutex are released.
*/
rw_mutex_shared_lock :: proc "contextless" (rw: ^RW_Mutex) {
	_rw_mutex_shared_lock(rw)
}

/*
Release the shared lock on a read-write mutex.

This procedure releases shared lock on the specified read-write mutex. When all
shared locks are released, all critical sections associated with the same
read-write mutex become open to other threads.
*/
rw_mutex_shared_unlock :: proc "contextless" (rw: ^RW_Mutex) {
	_rw_mutex_shared_unlock(rw)
}

/*
Try to acquire a shared lock on a read-write mutex.

This procedure attempts to acquire a lock on the specified read-write mutex. If
the mutex already has an exclusive lock held, this procedure returns `false`.
Otherwise, it acquires the lock on the mutex and returns `true`.

If the shared lock has been acquired, it causes all threads attempting to
acquire the exclusive lock to be blocked from entering any critical sections
associated with the same read-write mutex, until all shared locks are released.
*/
rw_mutex_try_shared_lock :: proc "contextless" (rw: ^RW_Mutex) -> bool {
	return _rw_mutex_try_shared_lock(rw)
}

/*
Guard the current scope with an exclusive lock on a read-write mutex.

This procedure acquires an exclusive lock on the specified read-write mutex.
This procedure automatically releases the lock at the end of the callee's scope.
If the mutex was already locked by readers or a writer, this procedure blocks,
until a lock can be acquired.

When an exclusive lock is acquired, all other threads attempting to acquire an
exclusive lock will be blocked from entering any critical sections associated
with the same read-write mutex, until the exclusive lock is released.

This procedure always returns `true`, which makes it easy to define a critical
section by running this procedure inside an `if` statement.

**Example**:

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
Guard the current scope with a shared lock on a read-write mutex.

This procedure acquires a shared lock on the specified read-write mutex. This
procedure automatically releases the lock at the end of the callee's scope. If
the mutex already has an associated exclusive lock, this procedure blocks, until
a lock can be acquired.

When a shared lock is obtained, all other threads attempting to obtain an
exclusive lock will be blocked from any critical sections, associated with the
same read-write mutex, until all shared locks are released.

This procedure always returns `true`, which makes it easy to define a critical
section by running this procedure inside an `if` statement.

**Example**:

	if rw_mutex_guard(&m) {
		...
	}
*/
@(deferred_in=rw_mutex_shared_unlock)
rw_mutex_shared_guard :: proc "contextless" (m: ^RW_Mutex) -> bool {
	rw_mutex_shared_lock(m)
	return true
}

/*
Recursive mutual exclusion lock.

Recurisve mutex is just like a plain mutex, except it allows reentrancy. In
order for a thread to release the mutex for other threads, the mutex needs to
be unlocked as many times, as it was locked.

When a lock is acquired on a recursive mutex, all other threads attempting to
acquire a lock on the same mutex will be blocked from any critical sections,
associated with the same recrusive mutex.

When a lock is acquired on a recursive mutex by a thread, that thread is allowed
to acquire another lock on the same mutex. When a thread has acquired the lock
on a recursive mutex, the recursive mutex will stay locked until the thread
releases the lock as many times as it has been locked by the thread.

**Note**: A recursive mutex must not be copied after first use (e.g., after
acquiring a lock). This is because, in order to coordinate with other threads,
all threads must watch the same memory address to know when the lock has been
released. Trying to use a copy of the lock at a different memory address will
result in broken and unsafe behavior. For this reason, mutexes are marked as
`#no_copy`.
*/
Recursive_Mutex :: struct #no_copy {
	impl: _Recursive_Mutex,
}

/*
Acquire a lock on a recursive mutex.

This procedure acquires a lock on the specified recursive mutex. If the lock is
acquired by a different thread, this procedure also blocks until the lock can be
acquired.

When the lock is acquired, all other threads attempting to acquire a lock will
be blocked from entering any critical sections associated with the same mutex,
until the lock is released.
*/
recursive_mutex_lock :: proc "contextless" (m: ^Recursive_Mutex) {
	_recursive_mutex_lock(m)
}

/*
Release a lock on a recursive mutex.

This procedure releases a lock on the specified recursive mutex. It also causes
the critical sections associated with the same mutex, to become open for other
threads for entering.
*/
recursive_mutex_unlock :: proc "contextless" (m: ^Recursive_Mutex) {
	_recursive_mutex_unlock(m)
}

/*
Try to acquire a lock on a recursive mutex.

This procedure attempts to acquire a lock on the specified recursive mutex. If
the recursive mutex is locked by other threads, this procedure returns `false`.
Otherwise it locks the mutex and returns `true`.

If the lock is acquired, all other threads attempting to obtain a lock will be
blocked from entering any critical sections associated with the same mutex,
until the lock is released.
*/
recursive_mutex_try_lock :: proc "contextless" (m: ^Recursive_Mutex) -> bool {
	return _recursive_mutex_try_lock(m)
}

/*
Guard the scope with a recursive mutex lock.

This procedure acquires a lock on the specified recursive mutex and
automatically releases it at the end of the callee's scope. If the recursive
mutex was already held by a another thread, this procedure also blocks until the
lock can be acquired.

When the lock is acquired all other threads attempting to take a lock will be
blocked from entering any critical sections associated with the same mutex,
until the lock is released.

This procedure always returns `true`, which makes it easy to define a critical
section by calling this procedure inside an `if` statement.

**Example**:

	if recursive_mutex_guard(&m) {
		...
	}
*/
@(deferred_in=recursive_mutex_unlock)
recursive_mutex_guard :: proc "contextless" (m: ^Recursive_Mutex) -> bool {
	recursive_mutex_lock(m)
	return true
}

/*
A condition variable.

`Cond` implements a condition variable, a rendezvous point for threads waiting
for signalling the occurence of an event. Condition variables are used in
conjuction with mutexes to provide a shared access to one or more shared
variable.

A typical usage of condition variable is as follows. A thread that intends to
modify a shared variable shall:

1. Acquire a lock on a mutex.
2. Modify the shared memory.
3. Release the lock.
3. Call `cond_signal` or `cond_broadcast`.

A thread that intends to wait on a shared variable shall:

1. Acquire a lock on a mutex.
2. Call `cond_wait` or `cond_wait_with_timeout` (will release the mutex).
3. Check the condition and keep waiting in a loop if not satisfied with result.

**Note**: A condition variable must not be copied after first use (e.g., after
waiting on it the first time). This is because, in order to coordinate with
other threads, all threads must watch the same memory address to know when the
lock has been released. Trying to use a copy of the lock at a different memory
address will result in broken and unsafe behavior. For this reason, condition
variables are marked as `#no_copy`.
*/
Cond :: struct #no_copy {
	impl: _Cond,
}

/*
Wait until the condition variable is signalled and release the associated mutex.

This procedure blocks the current thread until the specified condition variable
is signalled, or until a spurious wakeup occurs. In addition, if the condition
has been signalled, this procedure releases the lock on the specified mutex.

The mutex must be held by the calling thread, before calling the procedure.

**Note**: This procedure can return on a spurious wake-up, even if the condition
variable was not signalled by a thread.
*/
cond_wait :: proc "contextless" (c: ^Cond, m: ^Mutex) {
	_cond_wait(c, m)
}

/*
Wait until the condition variable is signalled or timeout is reached and release
the associated mutex.

This procedure blocks the current thread until the specified condition variable
is signalled, a timeout is reached, or until a spurious wakeup occurs. In
addition, if the condition has been signalled, this procedure releases the
lock on the specified mutex.

If the timeout was reached, this procedure returns `false`. Otherwise it returns
`true`.

Before this procedure is called the mutex must be held by the calling thread.
*/
cond_wait_with_timeout :: proc "contextless" (c: ^Cond, m: ^Mutex, duration: time.Duration) -> bool {
	if duration <= 0 {
		return false
	}
	return _cond_wait_with_timeout(c, m, duration)
}

/*
Wake up one thread that waits on a condition variable.

This procedure causes exactly one thread waiting on the condition variable to
wake up.
*/
cond_signal :: proc "contextless" (c: ^Cond) {
	_cond_signal(c)
}

/*
Wake up all threads that wait on a condition variable.

This procedure causes all threads waiting on the condition variable to wake up.
*/
cond_broadcast :: proc "contextless" (c: ^Cond) {
	_cond_broadcast(c)
}

/*
Semaphore.

When waited upon, semaphore blocks until the internal count is greater than
zero, then decrements the internal counter by one. Posting to the semaphore
increases the count by one, or the provided amount.

This type of synchronization primitives can be useful for implementing queues.
The internal counter of the semaphore can be thought of as the amount of items
in the queue. After a data has been pushed to the queue, the thread shall call
`sema_post()` procedure, increasing the counter. When a thread takes an item
from the queue to do the job, it shall call `sema_wait()`, waiting on the
semaphore counter to become non-zero and decreasing it, if necessary.

**Note**: A semaphore must not be copied after first use (e.g., after posting
to it). This is because, in order to coordinate with other threads, all threads
must watch the same memory address to know when the lock has been released.
Trying to use a copy of the lock at a different memory address will result in
broken and unsafe behavior. For this reason, semaphores are marked as `#no_copy`.
*/
Sema :: struct #no_copy {
	impl: _Sema,
}

/*
Increment the internal counter on a semaphore by the specified amount.

This procedure increments the internal counter of the semaphore. If any of the
threads were waiting on the semaphore, up to `count` of threads will continue
the execution and enter the critical section.
*/
sema_post :: proc "contextless" (s: ^Sema, count := 1) {
	_sema_post(s, count)
}

/*
Wait on a semaphore until the internal counter is non-zero.

This procedure blocks the execution of the current thread, until the semaphore
counter is non-zero, and atomically decrements it by one, once the wait has
ended.
*/
sema_wait :: proc "contextless" (s: ^Sema) {
	_sema_wait(s)
}

/*
Wait on a semaphore until the internal counter is non-zero or a timeout is reached.

This procedure blocks the execution of the current thread, until the semaphore
counter is non-zero, and if so atomically decrements it by one, once the wait
has ended. If the specified timeout is reached, the function returns `false`,
otherwise it returns `true`.
*/
sema_wait_with_timeout :: proc "contextless" (s: ^Sema, duration: time.Duration) -> bool {
	return _sema_wait_with_timeout(s, duration)
}

/*
Fast userspace mutual exclusion lock.

Futex is a fast userspace mutual exclusion lock, that uses a pointer to a 32-bit
value as an identifier of the queue of waiting threads. The value pointed to
by that pointer can be used to store extra data.

**IMPORTANT**: A futex must not be copied after first use (e.g., after waiting
on it the first time, or signalling it). This is because, in order to coordinate
with other threads, all threads must watch the same memory address. Trying to
use a copy of the lock at a different memory address will result in broken and
unsafe behavior.
*/
Futex :: distinct u32

/*
Sleep if the futex contains the expected value until it's signalled.

If the value of the futex is `expected`, this procedure blocks the execution of
the current thread, until the futex is woken up, or until a spurious wakeup
occurs.
*/
futex_wait :: proc "contextless" (f: ^Futex, expected: u32) {
	if u32(atomic_load_explicit(f, .Acquire)) != expected {
		return
	}
	ok := _futex_wait(f, expected)
	assert_contextless(ok, "futex_wait failure")
}

/*
Sleep if the futex contains the expected value until it's signalled or the
timeout is reached.

If the value of the futex is `expected`, this procedure blocks the execution of
the current thread, until the futex is signalled, a timeout is reached, or
until a spurious wakeup occurs.

This procedure returns `false` if the timeout was reached, `true` otherwise.
*/
futex_wait_with_timeout :: proc "contextless" (f: ^Futex, expected: u32, duration: time.Duration) -> bool {
	if u32(atomic_load_explicit(f, .Acquire)) != expected {
		return true
	}
	if duration <= 0 {
		return false
	}	
	
	return _futex_wait_with_timeout(f, expected, duration)
}

/*
Wake up a single thread waiting on a futex.
*/
futex_signal :: proc "contextless" (f: ^Futex) {
	_futex_signal(f)
}

/*
Wake up multiple threads waiting on a futex.
*/
futex_broadcast :: proc "contextless" (f: ^Futex) {
	_futex_broadcast(f)
}
