#+build darwin
package darwin

import "core:c"

@(export)
foreign import system "system:System"

Bool :: b8

// Opaque <sys/acl.h> access control list.
acl_t :: distinct rawptr

// Opaque <malloc/malloc.h> zone, only used through pointers.
malloc_zone_t :: struct {}

RUsage :: struct {
	ru_utime:    timeval,
	ru_stime:    timeval,
	ru_maxrss:   c.long,
	ru_ixrss:    c.long,
	ru_idrss:    c.long,
	ru_isrss:    c.long,
	ru_minflt:   c.long,
	ru_majflt:   c.long,
	ru_nswap:    c.long,
	ru_inblock:  c.long,
	ru_oublock:  c.long,
	ru_msgsnd:   c.long,
	ru_msgrcv:   c.long,
	ru_nsignals: c.long,
	ru_nvcsw:    c.long,
	ru_nivcsw:   c.long,
}

foreign system {
	__error :: proc() -> ^i32 ---
}

errno :: #force_inline proc "contextless" () -> i32 {
	return __error()^
}
