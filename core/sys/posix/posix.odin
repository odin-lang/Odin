/*
Raw bindings for most POSIX APIs.

Targets glibc and musl compatibility.

APIs that have been left out are due to not being useful,
being fully replaced (and better) by other Odin packages,
or when one of the targets hasn't implemented the API or option.

The struct fields that are cross-platform are documented with `[PSX]`.
Accessing these fields on one target should be the same on others.
Other fields are implementation specific.

Most macros have been reimplemented in Odin with inlined functions.

Unimplemented headers:
- aio.h
- complex.h | See `core:c/libc` and our own complex types
- cpio.h
- ctype.h | See `core:c/libc` for most of it
- ndbm.h
- fenv.h
- float.h
- fmtmsg.h
- ftw.h
- semaphore.h | See `core:sync`
- inttypes.h | See `core:c`
- iso646.h | Impossible
- math.h | See `core:c/libc`
- mqueue.h | Targets don't seem to have implemented it
- regex.h | See `core:regex`
- search.h | Not useful in Odin
- spawn.h | Use `fork`, `execve`, etc.
- stdarg.h | See `core:c/libc`
- stdint.h | See `core:c`
- stropts.h
- syslog.h
- pthread.h | Only the actual threads API is bound, see `core:sync` for synchronization primitives
- string.h | Most of this is not useful in Odin, only a select few symbols are bound
- tar.h
- tgmath.h
- trace.h
- wchar.h
- wctype.h

*/
package posix

import "base:intrinsics"

import "core:c"

result :: enum c.int {
 	// Use `errno` and `strerror` for more information.
	FAIL = -1,
	// Operation succeeded.
	OK = 0,
}

FD :: distinct c.int

@(private)
log2 :: intrinsics.constant_log2

when ODIN_OS == .Darwin && ODIN_ARCH == .amd64 {
	@(private)
	INODE_SUFFIX :: "$INODE64"
} else {
	@(private)
	INODE_SUFFIX :: ""
}

