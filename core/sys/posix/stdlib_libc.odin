#+build linux, windows, darwin, netbsd, openbsd, freebsd, haiku
package posix

import "base:intrinsics"

import "core:c"
import "core:c/libc"

when ODIN_OS == .Windows {
	foreign import lib "system:libucrt.lib"
} else when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// stdlib.h - standard library definitions

atof          :: libc.atof
atoi          :: libc.atoi
atol          :: libc.atol
atoll         :: libc.atoll
strtod        :: libc.strtod
strtof        :: libc.strtof
strtol        :: libc.strtol
strtoll       :: libc.strtoll
strtoul       :: libc.strtoul
strtoull      :: libc.strtoull

rand          :: libc.rand
srand         :: libc.srand

calloc        :: libc.calloc
malloc        :: libc.malloc
realloc       :: libc.realloc

abort         :: libc.abort
atexit        :: libc.atexit
at_quick_exit :: libc.at_quick_exit
exit          :: libc.exit
_Exit         :: libc._Exit
getenv        :: libc.getenv
quick_exit    :: libc.quick_exit
system        :: libc.system

bsearch       :: libc.bsearch
qsort         :: libc.qsort

abs           :: libc.abs
labs          :: libc.labs
llabs         :: libc.llabs
div           :: libc.div
ldiv          :: libc.ldiv
lldiv         :: libc.lldiv

mblen         :: libc.mblen
mbtowc        :: libc.mbtowc
wctomb        :: libc.wctomb

mbstowcs      :: libc.mbstowcs
wcstombs      :: libc.wcstombs

free :: #force_inline proc(ptr: $T) where intrinsics.type_is_pointer(T) || intrinsics.type_is_multi_pointer(T) || T == cstring {
	libc.free(rawptr(ptr))
}

foreign lib {

	/*
	Uses the string argument to set environment variable values. 

	Returns: 0 on success, non-zero (setting errno) on failure

	Example:
		if posix.putenv("HOME=/usr/home") != 0 {
			fmt.panicf("putenv failure: %v", posix.strerror(posix.errno()))
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/putenv.html ]]
	*/
	@(link_name=LPUTENV)
	putenv :: proc(string: cstring) -> c.int ---
}

EXIT_FAILURE :: libc.EXIT_FAILURE
EXIT_SUCCESS :: libc.EXIT_SUCCESS

RAND_MAX   :: libc.RAND_MAX
MB_CUR_MAX :: libc.MB_CUR_MAX

div_t   :: libc.div_t
ldiv_t  :: libc.ldiv_t
lldiv_t :: libc.lldiv_t

when ODIN_OS == .Windows {
	@(private) LPUTENV :: "_putenv"
} else when ODIN_OS == .NetBSD {
	@(private) LPUTENV :: "__putenv50"
} else {
	@(private) LPUTENV :: "putenv"
}
