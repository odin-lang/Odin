#+build js wasm32, js wasm64p32
#+private
package os2

import "base:runtime"

_heap_allocator_proc :: runtime.wasm_allocator_proc
