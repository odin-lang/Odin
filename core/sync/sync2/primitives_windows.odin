//+build windows
//+private
package sync2

import "core:time"
import win32 "core:sys/windows"

_current_thread_id :: proc "contextless" () -> int {
	return int(win32.GetCurrentThreadId());
}

_Mutex :: struct {
	srwlock: win32.SRWLOCK,
}

_mutex_lock :: proc(m: ^Mutex) {
	win32.AcquireSRWLockExclusive(&m.impl.srwlock);
}

_mutex_unlock :: proc(m: ^Mutex) {
	win32.ReleaseSRWLockExclusive(&m.impl.srwlock);
}

_mutex_try_lock :: proc(m: ^Mutex) -> bool {
	return bool(win32.TryAcquireSRWLockExclusive(&m.impl.srwlock));
}

_RW_Mutex :: struct {
	srwlock: win32.SRWLOCK,
}

_rw_mutex_lock :: proc(rw: ^RW_Mutex) {
	win32.AcquireSRWLockExclusive(&rw.impl.srwlock);
}

_rw_mutex_unlock :: proc(rw: ^RW_Mutex) {
	win32.ReleaseSRWLockExclusive(&rw.impl.srwlock);
}

_rw_mutex_try_lock :: proc(rw: ^RW_Mutex) -> bool {
	return bool(win32.TryAcquireSRWLockExclusive(&rw.impl.srwlock));
}

_rw_mutex_shared_lock :: proc(rw: ^RW_Mutex) {
	win32.AcquireSRWLockShared(&rw.impl.srwlock);
}

_rw_mutex_shared_unlock :: proc(rw: ^RW_Mutex) {
	win32.ReleaseSRWLockShared(&rw.impl.srwlock);
}

_rw_mutex_try_shared_lock :: proc(rw: ^RW_Mutex) -> bool {
	return bool(win32.TryAcquireSRWLockShared(&rw.impl.srwlock));
}


_Recursive_Mutex :: struct {
	owner:       u32,
	claim_count: i32,
}

_recursive_mutex_lock :: proc(m: ^Recursive_Mutex) {
	tid := win32.GetCurrentThreadId();
	for {
		prev_owner := atomic_compare_exchange_strong_acquire(&m.impl.owner, tid, 0);
		switch prev_owner {
		case 0, tid:
			m.impl.claim_count += 1;
			// inside the lock
			return;
		}

		win32.WaitOnAddress(
			&m.impl.owner,
			&prev_owner,
			size_of(prev_owner),
			win32.INFINITE,
		);
	}
}

_recursive_mutex_unlock :: proc(m: ^Recursive_Mutex) {
	m.impl.claim_count -= 1;
	if m.impl.claim_count != 0 {
		return;
	}
	atomic_exchange_release(&m.impl.owner, 0);
	win32.WakeByAddressSingle(&m.impl.owner);
	// outside the lock

}

_recursive_mutex_try_lock :: proc(m: ^Recursive_Mutex) -> bool {
	tid := win32.GetCurrentThreadId();
	prev_owner := atomic_compare_exchange_strong_acquire(&m.impl.owner, tid, 0);
	switch prev_owner {
	case 0, tid:
		m.impl.claim_count += 1;
		// inside the lock
		return true;
	}
	return false;
}




_Cond :: struct {
	cond: win32.CONDITION_VARIABLE,
}

_cond_wait :: proc(c: ^Cond, m: ^Mutex) {
	_ = win32.SleepConditionVariableSRW(&c.impl.cond, &m.impl.srwlock, win32.INFINITE, 0);
}

_cond_wait_with_timeout :: proc(c: ^Cond, m: ^Mutex, timeout: time.Duration) -> bool {
	ms := win32.DWORD((max(time.duration_nanoseconds(timeout), 0) + 999999)/1000000);
	return cast(bool)win32.SleepConditionVariableSRW(&c.impl.cond, &m.impl.srwlock, ms, 0);
}

_cond_signal :: proc(c: ^Cond) {
	win32.WakeConditionVariable(&c.impl.cond);
}

_cond_broadcast :: proc(c: ^Cond) {
	win32.WakeAllConditionVariable(&c.impl.cond);
}


_Sema :: struct {
	count: i32,
}

_sema_wait :: proc(s: ^Sema) {
	for {
		original_count := s.impl.count;
		for original_count == 0 {
			win32.WaitOnAddress(
				&s.impl.count,
				&original_count,
				size_of(original_count),
				win32.INFINITE,
			);
			original_count = s.impl.count;
		}
		if original_count == atomic_compare_exchange_strong(&s.impl.count, original_count-1, original_count) {
			return;
		}
	}
}

_sema_post :: proc(s: ^Sema, count := 1) {
	atomic_add(&s.impl.count, i32(count));
	if count == 1 {
		win32.WakeByAddressSingle(&s.impl.count);
	} else {
		win32.WakeByAddressAll(&s.impl.count);
	}
}
