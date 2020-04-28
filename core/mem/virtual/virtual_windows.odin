package virtual

import "core:sys/win32"
import "core:mem"
import "core:os"

PAGE_NOACCESS           :: 0x01;
PAGE_READONLY           :: 0x02;
PAGE_READWRITE          :: 0x04;
PAGE_WRITECOPY          :: 0x08;
PAGE_EXECUTE            :: 0x10;
PAGE_EXECUTE_READ       :: 0x20;
PAGE_EXECUTE_READWRITE  :: 0x40;
PAGE_EXECUTE_WRITECOPY  :: 0x80;


Memory_Access_Flag :: enum i32 {
	// NOTE(tetra): Order is important here.
	Read,
	Write,
	Execute,
}
Memory_Access_Flags :: bit_set[Memory_Access_Flag; i32]; // NOTE: For PROT_NONE, use `{}`.

access_to_flags :: proc(access: Memory_Access_Flags) -> u32 {
	flags: u32 = PAGE_NOACCESS;

	if .Write in access {
		if .Execute in access {
			flags = PAGE_EXECUTE_READWRITE;
		} else {
			assert(.Read in access, "Windows cannot set memory to write-only");
			flags = PAGE_READWRITE;
		}
	} else if .Read in access {
		if .Execute in access {
			flags = PAGE_EXECUTE_READ;
		} else {
			flags = PAGE_READONLY;
		}
	}

	return flags;
}


reserve :: proc(size: int, desired_base: rawptr = nil) -> (memory: []byte) {
	ptr := win32.virtual_alloc(desired_base, uint(size), win32.MEM_RESERVE, win32.PAGE_NOACCESS);
	return mem.slice_ptr(cast(^byte)ptr, size);
}

alloc :: proc(size: int, access := Memory_Access_Flags{.Read, .Write}, desired_base: rawptr = nil) -> (memory: []byte) {
	flags := access_to_flags(access);
	ptr := win32.virtual_alloc(desired_base, uint(size), win32.MEM_RESERVE | win32.MEM_COMMIT, flags);
	return mem.slice_ptr(cast(^byte)ptr, size);
}

// Frees the entire page that the given pointer is in.
free :: proc(memory: []byte) {
	if memory == nil do return;

	page_size := os.get_page_size();
	assert(mem.align_forward(&memory[0], uintptr(page_size)) == &memory[0], "must start at page boundary");

	// NOTE(tetra): On Windows, freeing virtual memory doesn't use lengths; the system
	// simply frees the block that was reserved originally.
	// For portability, we just ignore the length here, but still ask for the slice.
	ok := bool(win32.virtual_free(&memory[0], 0, win32.MEM_RELEASE));
	assert(ok);
}

// Commits pages that overlap the given memory block.
// The pages still do not take up system resources until they are written to.
// If you fail to do this before accessing the memory, it will segfault.
commit :: proc(memory: []byte, access := Memory_Access_Flags{.Read, .Write}) -> bool {
	assert(memory != nil);

	flags := access_to_flags(access);
	page_size := os.get_page_size();
	assert(mem.align_forward(&memory[0], uintptr(page_size)) == &memory[0], "must start at page boundary");
	ptr := win32.virtual_alloc(&memory[0], uint(len(memory)), win32.MEM_COMMIT, flags);
	return ptr != nil;
}

// Decommits pages that overlap the given memory block.
decommit :: proc(memory: []byte) {
	assert(memory != nil);

	page_size := os.get_page_size();
	assert(mem.align_forward(&memory[0], uintptr(page_size)) == &memory[0], "must start at page boundary");

	ok := bool(win32.virtual_free(&memory[0], uint(len(memory)), win32.MEM_DECOMMIT));
	assert(ok);
}

set_access :: proc(memory: []byte, access: Memory_Access_Flags) {
	assert(memory != nil);

	page_size := os.get_page_size();
	assert(mem.align_forward(&memory[0], uintptr(page_size)) == &memory[0], "must start at page boundary");

	flags := access_to_flags(access);
	unused: u32 = ---;
	ok := bool(win32.virtual_protect(&memory[0], uint(len(memory)), u32(flags), &unused));
	assert(ok);
}
