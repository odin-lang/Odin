package libc

// 7.14 Signal handling

when ODIN_OS == "windows" {
	foreign import libc "system:libucrt.lib"
} else when ODIN_OS == "darwin" {
	foreign import libc "system:System.framework"
} else {
	foreign import libc "system:c"
}

sig_atomic_t :: distinct atomic_int

SIG_ATOMIC_MIN :: min(sig_atomic_t)
SIG_ATOMIC_MAX :: max(sig_atomic_t)

@(default_calling_convention="c")
foreign libc {
	signal :: proc(sig: int, func: proc "c" (int)) -> proc "c" (int) ---
	raise  :: proc(sig: int) -> int ---
}

when ODIN_OS == "windows" {
	SIG_ERR :: rawptr(~uintptr(0)) 
	SIG_DFL :: rawptr(uintptr(0))
	SIG_IGN :: rawptr(uintptr(1))

	SIGABRT :: 22
	SIGFPE  :: 8
	SIGILL  :: 4
	SIGINT  :: 2
	SIGSEGV :: 11
	SIGTERM :: 15
}

when ODIN_OS == "linux" || ODIN_OS == "freebsd" {
	SIG_ERR  :: rawptr(~uintptr(0))
	SIG_DFL  :: rawptr(uintptr(0))
	SIG_IGN  :: rawptr(uintptr(1)) 

	SIGABRT  :: 6
	SIGFPE   :: 8
	SIGILL   :: 4
	SIGINT   :: 2
	SIGSEGV  :: 11
	SIGTERM  :: 15
}

when ODIN_OS == "darwin" {
	SIG_ERR  :: rawptr(~uintptr(0))
	SIG_DFL  :: rawptr(uintptr(0))
	SIG_IGN  :: rawptr(uintptr(1)) 

	SIGABRT  :: 6
	SIGFPE   :: 8
	SIGILL   :: 4
	SIGINT   :: 2
	SIGSEGV  :: 11
	SIGTERM  :: 15
}
