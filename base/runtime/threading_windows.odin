#+private
package runtime

foreign import Kernel32 "system:Kernel32.lib"

@(default_calling_convention="system")
foreign Kernel32 {
	GetCurrentThreadId :: proc() -> u32 ---
}

_get_current_thread_id :: proc "contextless" () -> int {
	return int(GetCurrentThreadId())
}
