package unix

import "core:c"

foreign import libc "system:c"

ERROR_NONE  :: 0
EAGAIN      :: 35

SIGCONT     :: 19

SIG_BLOCK   :: 1
SIG_UNBLOCK :: 2
SIG_SETMASK :: 3

siginfo_t :: struct { si_pad: [128]c.char }
sigset_t :: struct { bits: [4]c.uint }

foreign libc {
	sigemptyset  :: proc(set: ^sigset_t) -> c.int ---
	sigaddset    :: proc(set: ^sigset_t, _signal: c.int) -> c.int ---

	sigtimedwait :: proc(set: ^sigset_t, info: ^siginfo_t, timeout: ^timespec) -> c.int ---
	sigwait      :: proc(set: ^sigset_t, _signal: ^c.int) -> c.int ---

	@(private="file", link_name="__errno") get_error_location :: proc() -> ^c.int ---
}

errno :: #force_inline proc "contextless" () -> int {
	return int(get_error_location()^)
}
