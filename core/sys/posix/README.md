# POSIX

defines bindings for most posix APIs.

If a header is added, all of it must be implemented.

Each platform must define the exact same symbols, different values are allowed, even structs with different non-standard fields.

APIs part of extensions may be left out completely if one target doesn't implement it.

APIs with a direct replacement in `core` might not be implemented.

Macros are emulated with force inlined functions.

Struct fields defined by the posix standard (and thus portable) are documented with `[PSX]`.


ADD A TEST FOR SIGINFO, one thread signalling and retrieving the signal out of siginfo or something.
ADD A TEST FOR wait.h
ADD A TEST FOR pthread.
ADDD A test for stat.h.
ADD A TEST FOR setjmp.h.
HAIKU.

Unimplemented POSIX headers:

- aio.h
- complex.h | See `core:c/libc` and our own complex types
- cpio.h
- ctype.h | See `core:c/libc` for most of it
- ndbm.h | Never seen or heard of it
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

TODO:
- time.h | Docs
