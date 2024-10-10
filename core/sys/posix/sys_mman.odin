package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// mman.h - memory management declarations

foreign lib {
	/*
	Establish a mapping between an address space of a process and a memory object.

	Returns: MAP_FAILED (setting errno) on failure, the address in memory otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/mmap.html ]]
	*/
	mmap :: proc(
		addr:  rawptr,
		len:   c.size_t,
		prot:  Prot_Flags,
		flags: Map_Flags,
		fd:    FD    = -1,
		off:   off_t = 0,
	) -> rawptr ---

	/*
	Unmaps pages of memory.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/munmap.html ]]
	*/
	munmap :: proc(addr: rawptr, len: c.size_t) -> result ---

	/*
	Locks a range of the process address space.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/mlock.html ]]
	*/
	mlock :: proc(addr: rawptr, len: c.size_t) -> result ---

	/*
	Unlocks a range of the process address space.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/mlock.html ]]
	*/
	munlock :: proc(addr: rawptr, len: c.size_t) -> result ---

	/*
	Locks all pages of the process address space.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/mlockall.html ]]
	*/
	mlockall :: proc(flags: Lock_Flags) -> result ---

	/*
	Unlocks all pages of the process address space.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/mlockall.html ]]
	*/
	munlockall :: proc() -> result ---

	/*
	Set protection of a memory mapping.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/mprotect.html ]]
	*/
	mprotect :: proc(addr: rawptr, len: c.size_t, prot: Prot_Flags) -> result ---

	/*
	Write all modified data to permanent storage locations.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/msync.html ]]
	*/
	@(link_name=LMSYNC)
	msync :: proc(addr: rawptr, len: c.size_t, flags: Sync_Flags) -> result ---

	/*
	Advise the implementation of expected behavior of the application.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/posix_madvise.html ]]
	*/
	posix_madvise :: proc(addr: rawptr, len: c.size_t, advice: MAdvice) -> Errno ---

	/*
	Open a shared memory object.

	Returns: -1 (setting errno) on failure, an open file descriptor otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/shm_open.html ]]
	*/
	shm_open :: proc(name: cstring, oflag: O_Flags, mode: mode_t) -> FD ---

	/*
	Removes a shared memory object.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/shm_unlink.html ]]
	*/
	shm_unlink :: proc(name: cstring) -> result ---
}

#assert(_PROT_NONE == 0)
PROT_NONE :: Prot_Flags{}

Prot_Flag_Bits :: enum c.int {
	// Data can be executed.
	EXEC  = log2(PROT_EXEC),
	// Data can be read.
	READ  = log2(PROT_READ),
	// Data can be written.
	WRITE = log2(PROT_WRITE),
}
Prot_Flags :: bit_set[Prot_Flag_Bits; c.int]

Map_Flag_Bits :: enum c.int {
	// Interpret addr exactly.
	FIXED   = log2(MAP_FIXED),
	// Changes are private.
	PRIVATE = log2(MAP_PRIVATE),
	// Changes are shared.
	SHARED  = log2(MAP_SHARED),
}
Map_Flags :: bit_set[Map_Flag_Bits; c.int]

Lock_Flag_Bits :: enum c.int {
	// Lock all pages currently mapped into the address space of the process.
	CURRENT = log2(MCL_CURRENT),
	// Lock all pages that become mapped into the address space of the process in the future, 
	// when those mappings are established.
	FUTURE  = log2(MCL_FUTURE),
}
Lock_Flags :: bit_set[Lock_Flag_Bits; c.int]

Sync_Flags_Bits :: enum c.int {
	// Perform asynchronous writes.
	ASYNC      = log2(MS_ASYNC),
	// Invalidate cached data.
	INVALIDATE = log2(MS_INVALIDATE),

	// Perform synchronous writes.
 	// NOTE: use with `posix.MS_SYNC + { .OTHER_FLAG, .OTHER_FLAG }`, unfortunately can't be in
	// this bit set enum because it is 0 on some platforms and a value on others.
	// LOCAL = RTLD_LOCAL
	// SYNC       = MS_SYNC,

	_MAX = 31,
}
Sync_Flags :: bit_set[Sync_Flags_Bits; c.int]

MAdvice :: enum c.int {
	DONTNEED   = POSIX_MADV_DONTNEED,
	NORMAL     = POSIX_MADV_NORMAL,
	RANDOM     = POSIX_MADV_RANDOM,
	SEQUENTIAL = POSIX_MADV_SEQUENTIAL,
	WILLNEED   = POSIX_MADV_WILLNEED,
}

when ODIN_OS == .NetBSD {
	@(private) LMSYNC :: "__msync13"
} else {
	@(private) LMSYNC :: "msync"
}

when ODIN_OS == .Darwin || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD || ODIN_OS == .Linux {

	PROT_EXEC   :: 0x04
	_PROT_NONE  :: 0x00
	PROT_READ   :: 0x01
	PROT_WRITE  :: 0x02

	MAP_FIXED   :: 0x0010
	MAP_PRIVATE :: 0x0002
	MAP_SHARED  :: 0x0001

	when ODIN_OS == .Darwin || ODIN_OS == .Linux {
		MS_INVALIDATE :: 0x0002
		_MS_SYNC      :: 0x0010
	} else when ODIN_OS == .NetBSD {
		MS_INVALIDATE :: 0x0002
		_MS_SYNC      :: 0x0004
	} else when ODIN_OS == .OpenBSD {
		MS_INVALIDATE :: 0x0004
		_MS_SYNC      :: 0x0002
	}

	MS_ASYNC :: 0x0001
	MS_SYNC  :: Sync_Flags{Sync_Flags_Bits(log2(_MS_SYNC))}

	MCL_CURRENT :: 0x0001
	MCL_FUTURE  :: 0x0002

	MAP_FAILED :: rawptr(~uintptr(0))

	POSIX_MADV_DONTNEED   :: 4
	POSIX_MADV_NORMAL     :: 0
	POSIX_MADV_RANDOM     :: 1
	POSIX_MADV_SEQUENTIAL :: 2
	POSIX_MADV_WILLNEED   :: 3

} else when ODIN_OS == .FreeBSD {

	PROT_EXEC   :: 0x04
	_PROT_NONE  :: 0x00
	PROT_READ   :: 0x01
	PROT_WRITE  :: 0x02

	MAP_FIXED   :: 0x0010
	MAP_PRIVATE :: 0x0002
	MAP_SHARED  :: 0x0001

	MS_ASYNC      :: 0x0001
	MS_INVALIDATE :: 0x0002
	MS_SYNC       :: Sync_Flags{}

	MCL_CURRENT :: 0x0001
	MCL_FUTURE  :: 0x0002

	MAP_FAILED :: rawptr(~uintptr(0))

	POSIX_MADV_DONTNEED   :: 4
	POSIX_MADV_NORMAL     :: 0
	POSIX_MADV_RANDOM     :: 1
	POSIX_MADV_SEQUENTIAL :: 2
	POSIX_MADV_WILLNEED   :: 3

} else {
	#panic("posix is unimplemented for the current target")
}
