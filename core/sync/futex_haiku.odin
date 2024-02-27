//+private
package sync

import "core:c"
import "core:runtime"
import "core:sys/haiku"
import "core:sys/unix"
import "core:time"

@(private="file")
Wait_Node :: struct {
	thread:     unix.pthread_t,
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
		thread = unix.pthread_self(),
		futex  = f,
		prev   = head,
		next   = head.next,
	}

	waiter.prev.next = &waiter
	waiter.next.prev = &waiter

	old_mask, mask: haiku.sigset_t
	haiku.sigemptyset(&mask)
	haiku.sigaddset(&mask, haiku.SIGCONT)
	unix.pthread_sigmask(haiku.SIG_BLOCK, &mask, &old_mask)

	if u32(atomic_load_explicit(f, .Acquire)) == expect {
		waitq_unlock(waitq)
		defer waitq_lock(waitq)
		
		sig: c.int
		haiku.sigwait(&mask, &sig)
		errno := haiku.errno() 
		ok = errno == .OK
	}

	waiter.prev.next = waiter.next
	waiter.next.prev = waiter.prev

 	unix.pthread_sigmask(haiku.SIG_SETMASK, &old_mask, nil)

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
		thread = unix.pthread_self(),
		futex  = f,
		prev   = head,
		next   = head.next,
	}

	waiter.prev.next = &waiter
	waiter.next.prev = &waiter

	old_mask, mask: haiku.sigset_t
	haiku.sigemptyset(&mask)
	haiku.sigaddset(&mask, haiku.SIGCONT)
	unix.pthread_sigmask(haiku.SIG_BLOCK, &mask, &old_mask)

	if u32(atomic_load_explicit(f, .Acquire)) == expect {
		waitq_unlock(waitq)
		defer waitq_lock(waitq)
		
		info: haiku.siginfo_t
		ts := unix.timespec{
			tv_sec  = i64(duration / 1e9),
			tv_nsec = i64(duration % 1e9),
		}
		haiku.sigtimedwait(&mask, &info, &ts)
		errno := haiku.errno() 
		ok = errno == .EAGAIN || errno == .OK
	}

	waiter.prev.next = waiter.next
	waiter.next.prev = waiter.prev

 	unix.pthread_sigmask(haiku.SIG_SETMASK, &old_mask, nil)

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
			unix.pthread_kill(waiter.thread, haiku.SIGCONT)
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
			unix.pthread_kill(waiter.thread, haiku.SIGCONT)
		}
	}
}
