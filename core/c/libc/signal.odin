package libc

// 7.14 Signal handling

when ODIN_OS == .Windows {
	foreign import libc "system:libucrt.lib"
} else when ODIN_OS == .Darwin {
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

when ODIN_OS == .Windows {
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

when ODIN_OS == .Linux || ODIN_OS == .FreeBSD || ODIN_OS == .Haiku || ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD || ODIN_OS == .Darwin {
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
