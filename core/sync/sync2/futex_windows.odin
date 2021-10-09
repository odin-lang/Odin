//+private
//+build windows
package sync2

import "core:time"

foreign import Synchronization "system:Synchronization.lib"

@(default_calling_convention="c")
foreign Synchronization {
	WaitOnAddress :: proc(Address: rawptr, CompareAddress: rawptr, AddressSize: uint, dwMilliseconds: u32) -> b32 ---
	WakeByAddressSingle :: proc(Address: rawptr) ---
	WakeByAddressAll :: proc(Address: rawptr) ---
}

_futex_wait :: proc(f: ^Futex, expect: u32) -> Futex_Error {
	expect := expect
	ms :: ~u32(0) // infinite
	ok := WaitOnAddress(f, &expect, size_of(expect), ms)
	return nil if ok else .Timed_Out
}

_futex_wait_with_timeout :: proc(f: ^Futex, expect: u32, duration: time.Duration) -> Futex_Error {
	expect := expect
	
	ms: u32 = 0
	if duration >= 0 {
		ms = u32(u64(duration)/1e6)
	}
	
	ok := WaitOnAddress(f, &expect, size_of(expect), ms)
	return nil if ok else .Timed_Out
}

_futex_wake_single :: proc(f: ^Futex) {
	WakeByAddressSingle(f)
}

_futex_wake_all :: proc(f: ^Futex) {
	WakeByAddressAll(f)
}