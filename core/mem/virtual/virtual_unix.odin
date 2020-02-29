package virtual;

import "core:os"
import "core:mem"

foreign import libc "system:c"

foreign libc {
	@(link_name="mprotect") _unix_mprotect :: proc(base: rawptr, size: u64, prot: i32) -> i32 ---;
	@(link_name="mmap")     _unix_mmap     :: proc(base: rawptr, size: u64, prot: i32, flags: i32, fd: os.Handle, offset: i32) -> rawptr ---;
	@(link_name="munmap")   _unix_munmap   :: proc(base: rawptr, size: u64) -> i32 ---;
	@(link_name="madvise")  _unix_madvise  :: proc(addr: rawptr, size: u64, advise: i32) -> i32 ---;
}

PROT_NONE :: 0;
PROT_READ :: 1;
PROT_WRITE :: 2;
PROT_EXEC :: 4;
PROT_GROWSDOWN :: 0x01000000;
PROT_GROWSUP :: 0x02000000;


MAP_SHARED :: 0x01; // Share changes
MAP_PRIVATE :: 0x02; // Changes are private
MAP_SHARED_VALIDATE :: 0x03; // share + validate extension flags
MAP_TYPE :: 0x0f; // Mask for type of mapping

MAP_FIXED :: 0x10; // Interpret addr exactly
MAP_ANONYMOUS :: 0x20; // don't use a file

// MAP_ 0x0100 - 0x4000 flags are per architecture

MAP_POPULATE :: 0x8000; // populate (prefault) pagetables
MAP_NONBLOCK :: 0x10000; // do not block on IO
MAP_STACK :: 0x20000; // give out an address that is best suited for process/thread stacks
MAP_HUGETLB :: 0x40000; // create a huge page mapping
MAP_SYNC :: 0x80000; // perform synchronous page faults for the mapping
MAP_FIXED_NOREPLACE :: 0x100000; // MAP_FIXED which doesn't unmap underlying mapping
MAP_UNINITIALIZED :: 0x4000000; // For anonymous mmap, memory could be uninitialized

MADV_NORMAL :: 0;	/* No further special treatment.  */
MADV_RANDOM :: 1;	/* Expect random page references.  */
MADV_SEQUENTIAL :: 2;	/* Expect sequential page references.  */
MADV_WILLNEED :: 3;	/* Will need these pages.  */
MADV_DONTNEED :: 4;	/* Don't need these pages.  */
MADV_FREE :: 8;	/* Free pages only if memory pressure.  */
MADV_REMOVE :: 9;	/* Remove these pages and resources.  */
MADV_DONTFORK :: 10;	/* Do not inherit across fork.  */
MADV_DOFORK :: 11;	/* Do inherit across fork.  */
MADV_MERGEABLE :: 12;	/* KSM may merge identical pages.  */
MADV_UNMERGEABLE :: 13;	/* KSM may not merge identical pages.  */
MADV_HUGEPAGE :: 14;	/* Worth backing with hugepages.  */
MADV_NOHUGEPAGE :: 15;	/* Not worth backing with hugepages.  */
MADV_DONTDUMP :: 16;    /* Explicity exclude from the core dump,
                                   overrides the coredump filter bits.  */
MADV_DODUMP :: 17;	/* Clear the MADV_DONTDUMP flag.  */
MADV_WIPEONFORK :: 18;	/* Zero memory on fork, child only.  */
MADV_KEEPONFORK :: 19;	/* Undo MADV_WIPEONFORK.  */
MADV_HWPOISON :: 100;	/* Poison a page for testing.  */


Memory_Access_Flag :: enum i32 {
	// NOTE(tetra): Order is important here.
	Read,
	Write,
	Execute,
}
Memory_Access_Flags :: bit_set[Memory_Access_Flag; i32]; // NOTE: For PROT_NONE, use `{}`.

reserve :: proc(size: int, desired_base: rawptr = nil) -> (memory: []byte, ok: bool) {
	flags: i32 = MAP_PRIVATE | MAP_ANONYMOUS;
	if desired_base != nil do flags |= MAP_FIXED_NOREPLACE;

	ptr := _unix_mmap(desired_base, u64(size), PROT_NONE, flags, os.INVALID_HANDLE, 0);

	// NOTE: returns -1 on failure, and sets errno.
	ok = int(uintptr(ptr)) != -1;
	if !ok do return;

	memory = mem.slice_ptr(cast(^u8) ptr, size);
	return;
}

alloc :: proc(size: int, access := Memory_Access_Flags{.Read, .Write}, desired_base: rawptr = nil) -> (memory: []byte, ok: bool) {
	memory, ok = reserve(size, desired_base);
	if !ok do return;

	ok = commit(memory, access);
	return;
}

// Frees all pages that overlap the given memory block.
free :: proc(memory: []byte) {
	page_size := os.get_page_size();
	assert(mem.align_forward(&memory[0], uintptr(page_size)) == &memory[0], "must start at page boundary");
	// NOTE: returns -1 on failure, and sets errno.
	assert(_unix_munmap(&memory[0], u64(len(memory))) != -1);
}

// Commits pages that overlap the given memory block.
//
// NOTE(tetra): On Linux, presumably with overcommit on, this doesn't actually
// commit the memory; that only happens when you write to the pages.
commit :: proc(memory: []byte, access := Memory_Access_Flags{.Read, .Write}) -> bool {
	page_size := os.get_page_size();
	assert(mem.align_forward(&memory[0], uintptr(page_size)) == &memory[0], "must start at page boundary");
	ok := set_access(memory, access);
	_ = _unix_madvise(&memory[0], u64(len(memory)), MADV_WILLNEED) == 0; // ignored, since advisory is not required
	return ok;
}

decommit :: proc(memory: []byte) -> bool {
	page_size := os.get_page_size();
	assert(mem.align_forward(&memory[0], uintptr(page_size)) == &memory[0], "must start at page boundary");
	_ = _unix_madvise(&memory[0], u64(len(memory)), MADV_DONTNEED) == 0; // ignored, since advisory is not required
	ok := set_access(memory, {});
	return ok;
}

set_access :: proc(memory: []byte, access: Memory_Access_Flags) -> bool {
	page_size := os.get_page_size();
	assert(mem.align_forward(&memory[0], uintptr(page_size)) == &memory[0], "must start at page boundary");
	ret := _unix_mprotect(&memory[0], u64(len(memory)), transmute(i32) access);
	return ret == 0;
}

enclosing_page :: proc(ptr: rawptr) -> []byte {
	page_size := os.get_page_size();
	start := cast(^byte) mem.align_backward(ptr, uintptr(page_size));
	return mem.slice_ptr(start, page_size);
}

next_page :: proc(page: []byte) -> []byte {
	page_size := os.get_page_size();
	ptr := mem.align_forward(&page[0], uintptr(page_size));
	return mem.slice_ptr(cast(^byte) ptr, page_size);
}

previous_page :: proc(page: []byte) -> []byte {
	page_size := os.get_page_size();
	ptr := mem.align_backward(&page[0], uintptr(page_size));
	return mem.slice_ptr(cast(^byte) ptr, page_size);
}