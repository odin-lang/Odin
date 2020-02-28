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


Memory_Protection_Flag :: enum i32 {
	Read,
	Write,
	Execute,
}

// NOTE: For PROT_NONE, use `{}`.
Memory_Protection_Flags :: bit_set[Memory_Protection_Flag; i32];


alloc :: proc(size: int, protections: Memory_Protection_Flags = {.Read | .Write}, desired_base: rawptr = nil) -> (memory: []u8, ok: bool) {
	ptr := _unix_mmap(desired_base, u64(size), transmute(i32) protections, MAP_PRIVATE | MAP_ANONYMOUS, os.INVALID_HANDLE, 0);

	// NOTE: returns -1 on failure, and sets errno.
	ok = int(uintptr(ptr)) != -1;
	if !ok do return;

	memory = mem.slice_ptr(cast(^u8) ptr, size);
	return;
}

// Frees a region of virtual memory.
free :: proc(memory: []u8) {
	// NOTE: returns -1 on failure, and sets errno.
	page_size := os.get_page_size();
	assert(uintptr(&memory[0]) % uintptr(page_size) == 0, "must start at memory boundary");
	assert(_unix_munmap(&memory[0], u64(len(memory))) != -1);
}

commit :: proc(memory: []u8) -> bool {
	assert(uintptr(&memory[0]) % uintptr(os.get_page_size()) == 0, "must start at page boundary");
	ok := _unix_madvise(&memory[0], u64(len(memory)), MADV_WILLNEED) == 0;
	mem.set(&memory[0], 0, len(memory));
	return ok;
}

decommit :: proc(memory: []u8) -> bool {
	assert(uintptr(&memory[0]) % uintptr(os.get_page_size()) == 0, "must start at page boundary");
	return _unix_madvise(&memory[0], u64(len(memory)), MADV_DONTNEED) == 0;
}

enclosing_page :: proc(ptr: rawptr) -> []u8 {
	page_size := os.get_page_size();
	start := cast(^u8) mem.align_backward(ptr, uintptr(page_size));
	return mem.slice_ptr(start, page_size);
}

next_page :: proc(page: []u8) -> []u8 {
	page_size := os.get_page_size();
	assert(uintptr(&page[0]) % uintptr(page_size) == 0, "must start at page boundary");
	ptr := cast(^u8) &page[len(page)-1];
	return mem.slice_ptr(mem.ptr_offset(ptr, 1), page_size);
}

previous_page :: proc(page: []u8) -> []u8 {
	page_size := os.get_page_size();
	assert(uintptr(&page[0]) % uintptr(page_size) == 0, "must start at page boundary");
	ptr := cast(^u8) &page[0];
	return mem.slice_ptr(mem.ptr_offset(ptr, -page_size), page_size);
}

protect :: proc(memory: []u8, protections: Memory_Protection_Flags) {
	page_size := os.get_page_size();
	assert(uintptr(&memory[0]) % uintptr(page_size) == 0, "must start at page boundary");
	ret := _unix_mprotect(&memory[0], u64(len(memory)), transmute(i32) protections);
	assert(ret == 0, "memory could not be protected as requested");
}
