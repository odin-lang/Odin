#+private
#+build windows
package sync

import "core:time"

foreign import Synchronization "system:Synchronization.lib"
@(default_calling_convention="system")
foreign Synchronization {
	WakeByAddressSingle :: proc(Address: rawptr) ---
	WakeByAddressAll    :: proc(Address: rawptr) ---
}

foreign import Ntdll "system:Ntdll.lib"
@(default_calling_convention="system")
foreign Ntdll {
	RtlWaitOnAddress :: proc(Address: rawptr, CompareAddress: rawptr, AddressSize: uint, Timeout: ^i64) -> i32 ---
	RtlNtStatusToDosError :: proc(status: i32) -> u32 ---
	SetLastError :: proc(err: u32) ---
}


/*
	NOTE(bill, 2022-08-17)
	WaitOnAddress is implemented on top of RtlWaitOnAddress
	BUT requires taking the return value of it and if it is non-zero
	converting that status to a DOS error and then SetLastError
	If this is not done, then things don't work as expected when
	an error occurs

	GODDAMN MICROSOFT!
*/
CustomWaitOnAddress :: proc "system" (Address: rawptr, CompareAddress: rawptr, AddressSize: uint, Timeout: ^i64) -> bool {
	status := RtlWaitOnAddress(Address, CompareAddress, AddressSize, Timeout)
	if status != 0 {
		SetLastError(RtlNtStatusToDosError(status))
	}
	return status == 0
}


_futex_wait :: proc "contextless" (f: ^Futex, expect: u32) -> bool {
	expect := expect
	return CustomWaitOnAddress(f, &expect, size_of(expect), nil)
}

_futex_wait_with_timeout :: proc "contextless" (f: ^Futex, expect: u32, duration: time.Duration) -> bool {
	expect := expect
	// NOTE(bill): for some bizarre reason, this has to be a negative number
	timeout := -i64(duration / 100)
	return CustomWaitOnAddress(f, &expect, size_of(expect), &timeout)
}

_futex_signal :: proc "contextless" (f: ^Futex) {
	WakeByAddressSingle(f)
}

_futex_broadcast :: proc "contextless" (f: ^Futex) {
	WakeByAddressAll(f)
}