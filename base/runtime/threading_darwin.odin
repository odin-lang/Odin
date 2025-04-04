#+private
package runtime

foreign import lib "system:System.framework"

foreign lib {
	pthread_threadid_np :: proc "c" (rawptr, ^u64) -> i32 ---
}

_get_current_thread_id :: proc "contextless" () -> int {
	tid: u64
	result := pthread_threadid_np(nil, &tid)
	if result != 0 {
		panic_contextless("Failed to get current thread ID.")
	}
	return int(tid)
}
