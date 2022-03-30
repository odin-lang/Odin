//+private
//+build windows
package sync2

import "core:time"

foreign import Synchronization "system:Synchronization.lib"

@(default_calling_convention="stdcall")
foreign Synchronization {
	WaitOnAddress       :: proc(Address: rawptr, CompareAddress: rawptr, AddressSize: uint, Timeout: u32) -> b32 ---
	WakeByAddressSingle :: proc(Address: rawptr) ---
	WakeByAddressAll    :: proc(Address: rawptr) ---
}



_futex_wait :: proc(f: ^Futex, expect: u32) -> bool {
	expect := expect
	return bool(WaitOnAddress(f, &expect, size_of(expect), ~u32(0)))
}

_futex_wait_with_timeout :: proc(f: ^Futex, expect: u32, duration: time.Duration) -> bool {
	expect := expect
	timeout := u32(0)
	if duration > 0 {
		timeout = u32(duration/1e6)
	}
	return bool(WaitOnAddress(f, &expect, size_of(expect), timeout))
}

_futex_signal :: proc(f: ^Futex) {
	WakeByAddressSingle(f)
}

_futex_broadcast :: proc(f: ^Futex) {
	WakeByAddressAll(f)
}