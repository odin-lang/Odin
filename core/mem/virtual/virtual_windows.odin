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
	// if .Write in access {
	// 	flags |= PAGE_READWRITE;
	// 	assert(.Read in access, "Windows cannot set memory to be write-only");
	// }
	// if .Read in access {
	// 	flags |= PAGE_READONLY;
	// }
	// if .Execute in access {
	// 	flags |= PAGE_EXECUTE;
	// }

	assert(.Read in access, "Windows cannot set memory to write-only");

	if .Write in access {
		if .Execute in access {
			flags = PAGE_EXECUTE_READWRITE;
		} else {
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

reserve :: proc(size: int, desired_base: rawptr = nil) -> (memory: []byte, ok: bool) {
	ptr := win32.virtual_alloc(desired_base, uint(size), win32.MEM_RESERVE, win32.PAGE_NOACCESS);

	ok = ptr != nil;
	if !ok do return;

	memory = mem.slice_ptr(cast(^u8) ptr, size);
	return;
}

alloc :: proc(size: int, access := Memory_Access_Flags{.Read, .Write}, desired_base: rawptr = nil) -> (memory: []byte, ok: bool) {
	flags := access_to_flags(access);
	ptr := win32.virtual_alloc(desired_base, uint(size), win32.MEM_RESERVE | win32.MEM_COMMIT, flags);

	ok = ptr != nil;
	if !ok do return;

	memory = mem.slice_ptr(cast(^u8) ptr, size);
	return;
}

// Frees all pages that overlap the given memory block.
free :: proc(memory: []byte) {
	page_size := os.get_page_size();
	assert(mem.align_forward(&memory[0], uintptr(page_size)) == &memory[0], "must start at page boundary");

	ret := win32.virtual_free(&memory[0], 0, win32.MEM_RELEASE);
	assert(bool(ret));
}

// Commits pages that overlap the given memory block.
//
// NOTE(tetra): On Linux, presumably with overcommit on, this doesn't actually
// commit the memory; that only happens when you write to the pages.
commit :: proc(memory: []byte, access := Memory_Access_Flags{.Read, .Write}) -> bool {
	flags := access_to_flags(access);
	ptr := win32.virtual_alloc(&memory[0], uint(len(memory)), win32.MEM_COMMIT, flags);
	return ptr != nil;
}

decommit :: proc(memory: []byte) -> bool {
	page_size := os.get_page_size();
	assert(mem.align_forward(&memory[0], uintptr(page_size)) == &memory[0], "must start at page boundary");

	ret := win32.virtual_free(&memory[0], 0, win32.MEM_DECOMMIT);
	return bool(ret);
}

set_access :: proc(memory: []byte, access: Memory_Access_Flags) -> bool {
	page_size := os.get_page_size();
	assert(mem.align_forward(&memory[0], uintptr(page_size)) == &memory[0], "must start at page boundary");

	flags := access_to_flags(access);
	unused: u32;
	ret := win32.virtual_protect(&memory[0], uint(len(memory)), u32(flags), &unused);

	return bool(ret);
}
