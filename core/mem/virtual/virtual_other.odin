#+private
#+build !darwin
#+build !freebsd
#+build !openbsd
#+build !netbsd
#+build !linux
#+build !windows
#+build !wasm32
#+build !wasm64p32
package mem_virtual

_reserve :: proc "contextless" (size: uint, address_hint: uintptr) -> (data: []byte, err: Allocator_Error) {
	return nil, .Out_Of_Memory
}

_commit :: proc "contextless" (data: rawptr, size: uint) -> Allocator_Error {
	return .Out_Of_Memory
}

_decommit :: proc "contextless" (data: rawptr, size: uint) {
}

_release :: proc "contextless" (data: rawptr, size: uint) {
}

_protect :: proc "contextless" (data: rawptr, size: uint, flags: Protect_Flags) -> bool {
	return false
}

_map_file :: proc "contextless" (f: any, size: i64, flags: Map_File_Flags) -> (data: []byte, error: Map_File_Error) {
	return nil, .Map_Failure
}

_unmap_file :: proc "contextless" (data: []byte) {

}
