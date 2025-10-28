#+private
#+build netbsd
package os2

import "core:c"
foreign import libc "system:c"

@(private)
foreign libc {
	_lwp_self     :: proc() -> i32 ---

	@(link_name="sysctlbyname")
	_sysctlbyname :: proc(path: cstring, oldp: rawptr, oldlenp: rawptr, newp: rawptr, newlen: int) -> c.int ---
}

@(require_results)
_get_current_thread_id :: proc "contextless" () -> int {
	return int(_lwp_self())
}

_get_processor_core_count :: proc() -> int {
	count : int = 0
	count_size := size_of(count)
	if _sysctlbyname("hw.ncpu", &count, &count_size, nil, 0) == 0 {
		if count > 0 {
			return count
		}
	}

	return 1
}