//+private
//+build windows
package sync2

import "core:time"

foreign import Synchronization "system:Synchronization.lib"
foreign import NtDll "system:NtDll.lib"

@(default_calling_convention="stdcall")
foreign NtDll {
	RtlWaitOnAddress :: proc(Address: rawptr, CompareAddress: rawptr, AddressSize: uint, Timeout: ^i64) -> b32 ---
}

@(default_calling_convention="stdcall")
foreign Synchronization {
	WakeByAddressSingle :: proc(Address: rawptr) ---
	WakeByAddressAll :: proc(Address: rawptr) ---
}



_futex_wait :: proc(f: ^Futex, expect: u32) -> Futex_Error {
	expect := expect
	ok := RtlWaitOnAddress(f, &expect, size_of(expect), nil)
	return nil if ok else .Timed_Out
}

_futex_wait_with_timeout :: proc(f: ^Futex, expect: u32, duration: time.Duration) -> Futex_Error {
	expect := expect
	
	timeout: i64
	timeout_ptr: ^i64
	if duration > 0 {
		// In 100 ns units
		timeout = i64(timeout)/100
		timeout_ptr = &timeout
	}
	\
	ok := RtlWaitOnAddress(f, &expect, size_of(expect), timeout_ptr)
	return nil if ok else .Timed_Out
}

_futex_wake_single :: proc(f: ^Futex) {
	WakeByAddressSingle(f)
}

_futex_wake_all :: proc(f: ^Futex) {
	WakeByAddressAll(f)
}