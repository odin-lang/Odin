#+build js wasm32, js wasm64p32
#+private
package os

// None of this does anything on js/wasm.
// It's only here so importing `core:os` on wasm panics cleanly,
// without spamming about all sorts of missing procs and types.

import "base:intrinsics"

Read_Directory_Iterator_Impl :: struct {
	fullpath: [dynamic]byte,
	buf:      []byte,
	off:      int,
}

@(require_results)
_read_directory_iterator :: proc(it: ^Read_Directory_Iterator) -> (fi: File_Info, index: int, ok: bool) {
	return {}, -1, false
}

_read_directory_iterator_init :: proc(it: ^Read_Directory_Iterator, f: ^File) {

}

_read_directory_iterator_destroy :: proc(it: ^Read_Directory_Iterator) {

}