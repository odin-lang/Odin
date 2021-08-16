//+build linux
//+private
package sync2

// TODO(bill): remove libc
foreign import libc "system:c"

_current_thread_id :: proc "contextless" () -> int {
	foreign libc {
		syscall :: proc(number: i32, #c_vararg args: ..any) -> i32 ---
	}

	SYS_GETTID :: 186;
	return int(syscall(SYS_GETTID));
}
