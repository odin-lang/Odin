//+build darwin
//+private
package mem_virtual

foreign import libc "system:System"
import "core:c"

PROT_NONE  :: 0x0 /* [MC2] no permissions */
PROT_READ  :: 0x1 /* [MC2] pages can be read */
PROT_WRITE :: 0x2 /* [MC2] pages can be written */
PROT_EXEC  :: 0x4 /* [MC2] pages can be executed */

// Sharing options
MAP_SHARED    :: 0x1 /* [MF|SHM] share changes */
MAP_PRIVATE   :: 0x2 /* [MF|SHM] changes are private */

// Other flags
MAP_FIXED        :: 0x0010 /* [MF|SHM] interpret addr exactly */
MAP_RENAME       :: 0x0020 /* Sun: rename private pages to file */
MAP_NORESERVE    :: 0x0040 /* Sun: don't reserve needed swap area */
MAP_RESERVED0080 :: 0x0080 /* previously unimplemented MAP_INHERIT */
MAP_NOEXTEND     :: 0x0100 /* for MAP_FILE, don't change file size */
MAP_HASSEMAPHORE :: 0x0200 /* region may contain semaphores */
MAP_NOCACHE      :: 0x0400 /* don't cache pages for this mapping */
MAP_JIT          :: 0x0800 /* Allocate a region that will be used for JIT purposes */

// Mapping type
MAP_FILE         :: 0x0000  /* map from file (default) */
MAP_ANONYMOUS    :: 0x1000  /* allocated from memory, swap space */


/*
 * The MAP_RESILIENT_* flags can be used when the caller wants to map some
 * possibly unreliable memory and be able to access it safely, possibly
 * getting the wrong contents rather than raising any exception.
 * For safety reasons, such mappings have to be read-only (PROT_READ access
 * only).
 *
 * MAP_RESILIENT_CODESIGN:
 *      accessing this mapping will not generate code-signing violations,
 *	even if the contents are tainted.
 * MAP_RESILIENT_MEDIA:
 *	accessing this mapping will not generate an exception if the contents
 *	are not available (unreachable removable or remote media, access beyond
 *	end-of-file, ...).  Missing contents will be replaced with zeroes.
 */
MAP_RESILIENT_CODESIGN :: 0x2000 /* no code-signing failures */
MAP_RESILIENT_MEDIA    :: 0x4000 /* no backing-store failures */

MAP_32BIT        :: 0x8000          /* Return virtual addresses <4G only */

// Flags used to support translated processes.
MAP_TRANSLATED_ALLOW_EXECUTE :: 0x20000 /* allow execute in translated processes */
MAP_UNIX03       :: 0x40000 /* UNIX03 compliance */

// Process memory locking
MCL_CURRENT     :: 0x0001  /* [ML] Lock only current memory */
MCL_FUTURE      :: 0x0002  /* [ML] Lock all future memory as well */

MADV_NORMAL      :: 0 /* [MC1] no further special treatment */
MADV_RANDOM      :: 1 /* [MC1] expect random page refs */
MADV_SEQUENTIAL  :: 2 /* [MC1] expect sequential page refs */
MADV_WILLNEED    :: 3 /* [MC1] will need these pages */
MADV_DONTNEED    :: 4 /* [MC1] dont need these pages */
MADV_FREE        :: 5 /* pages unneeded, discard contents */
MADV_ZERO_WIRED_PAGES :: 6 /* zero the wired pages that have not been unwired before the entry is deleted */
MADV_FREE_REUSABLE :: 7 /* pages can be reused (by anyone) */
MADV_FREE_REUSE  :: 8 /* caller wants to reuse those pages */
MADV_CAN_REUSE   :: 9
MADV_PAGEOUT     :: 10 /* page out now (internal only) */

// msync() flags
MS_ASYNC        :: 0x0001  /* [MF|SIO] return immediately */
MS_INVALIDATE   :: 0x0002  /* [MF|SIO] invalidate all cached data */
MS_SYNC         :: 0x0010  /* [MF|SIO] msync synchronously */
MS_KILLPAGES    :: 0x0004  /* invalidate pages, leave mapped */
MS_DEACTIVATE   :: 0x0008  /* deactivate pages, leave mapped */

// Return bits from mincore
MINCORE_INCORE           :: 0x1      /* Page is incore */
MINCORE_REFERENCED       :: 0x2      /* Page has been referenced by us */
MINCORE_MODIFIED         :: 0x4      /* Page has been modified by us */
MINCORE_REFERENCED_OTHER :: 0x8      /* Page has been referenced */
MINCORE_MODIFIED_OTHER   :: 0x10     /* Page has been modified */
MINCORE_PAGED_OUT        :: 0x20     /* Page has been paged out */
MINCORE_COPIED           :: 0x40     /* Page has been copied */
MINCORE_ANONYMOUS        :: 0x80     /* Page belongs to an anonymous object */

// Allocation failure result
MAP_FAILED : rawptr = rawptr(~uintptr(0))

foreign libc {
	@(link_name="mlockall")         _mlockall           :: proc(flags: c.int) -> c.int ---
	@(link_name="munlockall")       _munlockall         :: proc() -> c.int ---
	@(link_name="mlock")            _mlock              :: proc(addr: rawptr, len: c.size_t) -> c.int ---
	@(link_name="mmap")             _mmap               :: proc(addr: rawptr, len: c.size_t, prot: c.int, flags: c.int, fd: c.int, offset: int) -> rawptr ---
	@(link_name="mprotect")         _mprotect           :: proc(addr: rawptr, len: c.size_t, prot: c.int) -> c.int ---
	@(link_name="msync")            _msync              :: proc(addr: rawptr, len: c.size_t) -> c.int ---
	@(link_name="munlock")          _munlock            :: proc(addr: rawptr, len: c.size_t) -> c.int ---
	@(link_name="munmap")           _munmap             :: proc(addr: rawptr, len: c.size_t) -> c.int ---
	@(link_name="shm_open")         _shm_open           :: proc(name: cstring, oflag: c.int, #c_vararg args: ..any) -> c.int ---
	@(link_name="shm_unlink")       _shm_unlink         :: proc(name: cstring) -> c.int ---
	@(link_name="posix_madvise")    _posix_madvise      :: proc(addr: rawptr, len: c.size_t, advice: c.int) -> c.int ---
	@(link_name="madvise")          _madvise            :: proc(addr: rawptr, len: c.size_t, advice: c.int) -> c.int ---
	@(link_name="mincore")          _mincore            :: proc(addr: rawptr, len: c.size_t, vec: cstring) -> c.int ---
	@(link_name="minherit")         _minherit           :: proc(addr: rawptr, len: c.size_t, inherit: c.int) -> c.int ---
}


_reserve :: proc "contextless" (size: uint) -> (data: []byte, err: Allocator_Error) {
	result := _mmap(nil, size, PROT_NONE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0)
	if result == MAP_FAILED {
		return nil, .Out_Of_Memory
	}
	return ([^]byte)(uintptr(result))[:size], nil
}

_commit :: proc "contextless" (data: rawptr, size: uint) -> Allocator_Error {
	result := _mprotect(data, size, PROT_READ|PROT_WRITE)
	if result != 0 {
		return .Out_Of_Memory
	}
	return nil
}
_decommit :: proc "contextless" (data: rawptr, size: uint) {
	_mprotect(data, size, PROT_NONE)
	_madvise(data, size, MADV_FREE)
}
_release :: proc "contextless" (data: rawptr, size: uint) {
	_munmap(data, size)
}
_protect :: proc "contextless" (data: rawptr, size: uint, flags: Protect_Flags) -> bool {
	pflags: c.int
	pflags = PROT_NONE
	if .Read    in flags { pflags |= PROT_READ  }
	if .Write   in flags { pflags |= PROT_WRITE }
	if .Execute in flags { pflags |= PROT_EXEC  }
	err := _mprotect(data, size, pflags)
	return err == 0
}


_platform_memory_init :: proc() {
	DEFAULT_PAGE_SIZE = 4096
	
	// is power of two
	assert(DEFAULT_PAGE_SIZE != 0 && (DEFAULT_PAGE_SIZE & (DEFAULT_PAGE_SIZE-1)) == 0)
}


_map_file :: proc "contextless" (fd: uintptr, size: i64, flags: Map_File_Flags) -> (data: []byte, error: Map_File_Error) {
	prot, mflags: c.int
	if .Read in flags {
		prot |= PROT_READ
	}
	if .Write in flags {
		prot |= PROT_WRITE
	}
	mflags |= MAP_SHARED
	addr := _mmap(nil, c.size_t(size), prot, mflags, i32(fd), 0)
	if addr == nil {
		return nil, .Map_Failure
	}
	return ([^]byte)(addr)[:size], nil
}
