//+private
//+build windows
package sync

import "core:time"

foreign import Synchronization "system:Synchronization.lib"
@(default_calling_convention="stdcall")
foreign Synchronization {
	WakeByAddressSingle :: proc(Address: rawptr) ---
	WakeByAddressAll    :: proc(Address: rawptr) ---
}

foreign import Ntdll "system:Ntdll.lib"
@(default_calling_convention="stdcall")
foreign Ntdll {
	RtlWaitOnAddress :: proc(Address: rawptr, CompareAddress: rawptr, AddressSize: uint, Timeout: ^i64) -> i32 ---
}

_futex_wait :: proc(f: ^Futex, expect: u32) -> bool {
	expect := expect
	return 0 == RtlWaitOnAddress(f, &expect, size_of(expect), nil)
}

_futex_wait_with_timeout :: proc(f: ^Futex, expect: u32, duration: time.Duration) -> bool {
	expect := expect
	// NOTE(bill): for some bizarre reason, this has be a negative number
	timeout := -i64(duration / 100)
	return 0 == RtlWaitOnAddress(f, &expect, size_of(expect), &timeout)
}

_futex_signal :: proc(f: ^Futex) {
	WakeByAddressSingle(f)
}

_futex_broadcast :: proc(f: ^Futex) {
	WakeByAddressAll(f)
}