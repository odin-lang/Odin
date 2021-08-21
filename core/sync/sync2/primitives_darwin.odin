//+build darwin
//+private
package sync2

import "core:time"
import "core:c"
import "core:intrinsics"

foreign import pthread "System.framework"

_current_thread_id :: proc "contextless" () -> int {
	tid: u64;
	// NOTE(Oskar): available from OSX 10.6 and iOS 3.2.
	// For older versions there is `syscall(SYS_thread_selfid)`, but not really
	// the same thing apparently.
	foreign pthread { pthread_threadid_np :: proc "c" (rawptr, ^u64) -> c.int ---; }
	pthread_threadid_np(nil, &tid);
	return int(tid);
}

foreign {
	@(link_name="usleep")
	_darwin_usleep :: proc "c" (us: uint) -> i32 ---
	@(link_name="sched_yield")
	_darwin_sched_yield :: proc "c" () -> i32 ---
}

_atomic_try_wait_slow :: proc(ptr: ^u32, val: u32) {
	history: uint = 10;
	for {
		// Exponential wait
		_darwin_usleep(history >> 2);
		history += history >> 2;
		if history > (1 << 10) {
			history = 1 << 10;
		}

		if atomic_load(ptr) != val {
			break;
		}
	}
}

_atomic_wait :: proc(ptr: ^u32, val: u32) {
	if intrinsics.expect(atomic_load(ptr) != val, true) {
		return;
	}
	for i in 0..<16 {
		if atomic_load(ptr) != val {
			return;
		}
		if i < 12 {
			intrinsics.cpu_relax();
		} else {
			_darwin_sched_yield();
		}
	}

	for val == atomic_load(ptr) {
		_atomic_try_wait_slow(ptr, val);
	}
}


_Mutex :: struct {

}

_mutex_lock :: proc(m: ^Mutex) {
}

_mutex_unlock :: proc(m: ^Mutex) {
}

_mutex_try_lock :: proc(m: ^Mutex) -> bool {
	return false;
}

_RW_Mutex :: struct {
}

_rw_mutex_lock :: proc(rw: ^RW_Mutex) {
}

_rw_mutex_unlock :: proc(rw: ^RW_Mutex) {
}

_rw_mutex_try_lock :: proc(rw: ^RW_Mutex) -> bool {
	return false;
}

_rw_mutex_shared_lock :: proc(rw: ^RW_Mutex) {
}

_rw_mutex_shared_unlock :: proc(rw: ^RW_Mutex) {
}

_rw_mutex_try_shared_lock :: proc(rw: ^RW_Mutex) -> bool {
	return false;
}


_Recursive_Mutex :: struct {
}

_recursive_mutex_lock :: proc(m: ^Recursive_Mutex) {
}

_recursive_mutex_unlock :: proc(m: ^Recursive_Mutex) {
}

_recursive_mutex_try_lock :: proc(m: ^Recursive_Mutex) -> bool {
	return false;
}




_Cond :: struct {
}

_cond_wait :: proc(c: ^Cond, m: ^Mutex) {
}

_cond_wait_with_timeout :: proc(c: ^Cond, m: ^Mutex, timeout: time.Duration) -> bool {
	return false;
}

_cond_signal :: proc(c: ^Cond) {
}

_cond_broadcast :: proc(c: ^Cond) {
}


_Sema :: struct {
}

_sema_wait :: proc(s: ^Sema) {
}

_sema_post :: proc(s: ^Sema, count := 1) {
}
