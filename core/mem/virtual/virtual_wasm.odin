#+private
#+build wasm32, wasm64p32
package mem_virtual

import "base:intrinsics"
import "base:runtime"
import "core:mem"

@(private="file")
backing_allocator :: proc() -> runtime.Allocator {
	when ODIN_OS == .Orca {
		return runtime.heap_allocator()
	} else {
		return runtime.default_wasm_allocator()
	}
}

_reserve :: proc "contextless" (size: uint, address_hint: uintptr) -> (data: []byte, err: Allocator_Error) {
	if size == 0 || size > uint(max(int)) {
		return nil, .Out_Of_Memory
	}
	context = runtime.default_context()
	return runtime.mem_alloc(int(size), mem.PAGE_SIZE, backing_allocator())
}

_commit :: proc "contextless" (data: rawptr, size: uint) -> Allocator_Error {
	return nil
}

_decommit :: proc "contextless" (data: rawptr, size: uint) {
	intrinsics.mem_zero(data, int(size))
}

_release :: proc "contextless" (data: rawptr, size: uint) {
	context = runtime.default_context()
	runtime.mem_free(data, backing_allocator())
}

_protect :: proc "contextless" (data: rawptr, size: uint, flags: Protect_Flags) -> bool {
	return false
}

_map_file :: proc "contextless" (f: any, size: i64, flags: Map_File_Flags) -> (data: []byte, error: Map_File_Error) {
	return nil, .Map_Failure
}

_unmap_file :: proc "contextless" (data: []byte) {

}
