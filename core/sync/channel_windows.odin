package sync

import "intrinsics"
import win32 "core:sys/windows"
import "core:time"

raw_channel_wait_queue_wait_on :: proc(state: ^uintptr, timeout: time.Duration) {
	ms := win32.DWORD(win32.INFINITE);
	if max(time.Duration) != SELECT_MAX_TIMEOUT {
		ms = win32.DWORD((max(time.duration_nanoseconds(timeout), 0) + 999999)/1000000);
	}

	v := intrinsics.atomic_load(state);
	for v == 0 {
		win32.WaitOnAddress(state, &v, size_of(state^), ms);
		v = intrinsics.atomic_load(state);
	}
	intrinsics.atomic_store(state, 0);
}

raw_channel_wait_queue_signal :: proc(q: ^Raw_Channel_Wait_Queue) {
	for x := q; x != nil; x = x.next {
		intrinsics.atomic_add(x.state, 1);
		win32.WakeByAddressSingle(x.state);
	}
}

raw_channel_wait_queue_broadcast :: proc(q: ^Raw_Channel_Wait_Queue) {
	for x := q; x != nil; x = x.next {
		intrinsics.atomic_add(x.state, 1);
		win32.WakeByAddressAll(x.state);
	}
}
