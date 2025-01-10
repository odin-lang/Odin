#+private
package sync

import "core:sys/haiku"
import "core:sys/posix"
import "core:time"

@(private="file")
Wait_Node :: struct {
	thread:     posix.pthread_t,
	futex:      ^Futex,
	prev, next: ^Wait_Node,
}
@(private="file")
atomic_flag :: distinct bool
@(private="file")
Wait_Queue :: struct {
	lock: atomic_flag,
	list: Wait_Node,
}
@(private="file")
waitq_lock :: proc "contextless" (waitq: ^Wait_Queue) {
	for cast(bool)atomic_exchange_explicit(&waitq.lock, atomic_flag(true), .Acquire) {
		cpu_relax() // spin...
	}
}
@(private="file")
waitq_unlock :: proc "contextless" (waitq: ^Wait_Queue) {
	atomic_store_explicit(&waitq.lock, atomic_flag(false), .Release)
}

// FIXME: This approach may scale badly in the future,
// possible solution - hash map (leads to deadlocks now).
@(private="file")
g_waitq: Wait_Queue

@(init, private="file")
g_waitq_init :: proc() {
	g_waitq = {
		list = {
			prev = &g_waitq.list,
			next = &g_waitq.list,
		},
	}
}

@(private="file")
get_waitq :: #force_inline proc "contextless" (f: ^Futex) -> ^Wait_Queue {
	_ = f
	return &g_waitq
}

_futex_wait :: proc "contextless" (f: ^Futex, expect: u32) -> (ok: bool) {
	waitq := get_waitq(f)
	waitq_lock(waitq)
	defer waitq_unlock(waitq)

	head   := &waitq.list
	waiter := Wait_Node{
		thread = posix.pthread_self(),
		futex  = f,
		prev   = head,
		next   = head.next,
	}

	waiter.prev.next = &waiter
	waiter.next.prev = &waiter

	old_mask, mask: posix.sigset_t
	posix.sigemptyset(&mask)
	posix.sigaddset(&mask, .SIGCONT)
	posix.pthread_sigmask(.BLOCK, &mask, &old_mask)

	if u32(atomic_load_explicit(f, .Acquire)) == expect {
		waitq_unlock(waitq)
		defer waitq_lock(waitq)
		
		sig: posix.Signal
		errno := posix.sigwait(&mask, &sig) 
		ok = errno == nil
	}

	waiter.prev.next = waiter.next
	waiter.next.prev = waiter.prev

	_ = posix.pthread_sigmask(.SETMASK, &old_mask, nil)

 	// FIXME: Add error handling!
	return
}

_futex_wait_with_timeout :: proc "contextless" (f: ^Futex, expect: u32, duration: time.Duration) -> (ok: bool) {
	if duration <= 0 {
		return false
	}
	waitq := get_waitq(f)
	waitq_lock(waitq)
	defer waitq_unlock(waitq)

	head   := &waitq.list
	waiter := Wait_Node{
		thread = posix.pthread_self(),
		futex  = f,
		prev   = head,
		next   = head.next,
	}

	waiter.prev.next = &waiter
	waiter.next.prev = &waiter

	old_mask, mask: posix.sigset_t
	posix.sigemptyset(&mask)
	posix.sigaddset(&mask, .SIGCONT)
	posix.pthread_sigmask(.BLOCK, &mask, &old_mask)

	if u32(atomic_load_explicit(f, .Acquire)) == expect {
		waitq_unlock(waitq)
		defer waitq_lock(waitq)
		
		info: posix.siginfo_t
		ts := posix.timespec{
			tv_sec  = posix.time_t(i64(duration / 1e9)),
			tv_nsec = i64(duration % 1e9),
		}
		haiku.sigtimedwait(&mask, &info, &ts)
		errno := posix.errno() 
		ok = errno == .EAGAIN || errno == nil
	}

	waiter.prev.next = waiter.next
	waiter.next.prev = waiter.prev

	posix.pthread_sigmask(.SETMASK, &old_mask, nil)

	// FIXME: Add error handling!
	return
}

_futex_signal :: proc "contextless" (f: ^Futex) {
	waitq := get_waitq(f)
	waitq_lock(waitq)
	defer waitq_unlock(waitq)

	head := &waitq.list
	for waiter := head.next; waiter != head; waiter = waiter.next {
		if waiter.futex == f {
			posix.pthread_kill(waiter.thread, .SIGCONT)
			break
		}
	}
}

_futex_broadcast :: proc "contextless" (f: ^Futex) {
	waitq := get_waitq(f)
	waitq_lock(waitq)
	defer waitq_unlock(waitq)

	head := &waitq.list
	for waiter := head.next; waiter != head; waiter = waiter.next {
		if waiter.futex == f {
			posix.pthread_kill(waiter.thread, .SIGCONT)
		}
	}
}
