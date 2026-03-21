#+private
#+build freebsd
package os

foreign import libc "system:c"
foreign import dl "system:dl"

foreign libc {
	@(link_name="sysctlbyname")
	_sysctlbyname :: proc(path: cstring, oldp: rawptr, oldlenp: rawptr, newp: rawptr, newlen: int) -> i32 ---
}

foreign dl {
	@(link_name="pthread_getthreadid_np")
	pthread_getthreadid_np :: proc() -> i32 ---
}

@(require_results)
_get_current_thread_id :: proc "contextless" () -> int {
	return int(pthread_getthreadid_np())
}

@(require_results)
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
